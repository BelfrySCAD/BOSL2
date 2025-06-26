//////////////////////////////////////////////////////////////////////
// LibFile: utility.scad
//   Functions for type checking, handling undefs, processing function arguments,
//   and testing. 
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Data Management
// FileSummary: Type checking, dealing with undefs, processing function args
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////



// Section: Type Checking


// Function: typeof()
// Synopsis: Returns a string representing the type of the value.
// Topics: Type Checking
// See Also: is_type()
// Usage:
//   typ = typeof(x);
// Description:
//   Returns a string representing the type of the value.  One of "undef", "boolean", "number", "nan", "string", "list", "range", "function" or "invalid".
//   Some malformed "ranges", like '[0:NAN:INF]' and '[0:"a":INF]', may be classified as "undef" or "invalid".
// Arguments:
//   x = value whose type to check
// Example:
//   typ = typeof(undef);  // Returns: "undef"
//   typ = typeof(true);  // Returns: "boolean"
//   typ = typeof(42);  // Returns: "number"
//   typ = typeof(NAN);  // Returns: "nan"
//   typ = typeof("foo");  // Returns: "string"
//   typ = typeof([3,4,5]);  // Returns: "list"
//   typ = typeof([3:1:8]);  // Returns: "range"
//   typ = typeof(function (x,y) x+y);  // Returns: "function"
function typeof(x) =
    is_undef(x)? "undef" :
    is_bool(x)? "boolean" :
    is_num(x)? "number" :
    is_nan(x)? "nan" :
    is_string(x)? "string" :
    is_list(x)? "list" :
    is_range(x) ? "range" :
    version_num()>20210000 && is_function(x) ? "function" :
    "invalid";


// Function: is_type()
// Synopsis: Returns true if the type of 'x' is one of those in the list `types`.
// Topics: Type Checking
// See Also: typeof()
// Usage:
//   bool = is_type(x, types);
// Description:
//   Returns true if the type of the value `x` is one of those given as strings in the list `types`. 
//   Valid types are "undef", "boolean", "number", "nan", "string", "list", "range", or "function".
// Arguments:
//   x = The value to check the type of.
//   types = A list of types to check 
// Example:
//   is_str_or_list = is_type("foo", ["string","list"]);   // Returns: true
//   is_str_or_list2 = is_type([1,2,3], ["string","list"]);  // Returns: true
//   is_str_or_list3 = is_type(2, ["string","list"]);  // Returns: false
//   is_str = is_type("foo", "string");  // Returns: true
//   is_str2 = is_type([3,4], "string");  // Returns: false
//   is_str3 = is_type(["foo"], "string");  // Returns: false
//   is_str4 = is_type(3, "string");  // Returns: false
function is_type(x,types) =
    is_list(types)? in_list(typeof(x),types) :
    is_string(types)? typeof(x) == types :
    assert(is_list(types)||is_string(types));


// Function: is_def()
// Synopsis: Returns true if `x` is not `undef`.
// Topics: Type Checking
// See Also: typeof(), is_type(), is_str()
// Usage:
//   bool = is_def(x);
// Description:
//   Returns true if `x` is not `undef`.  False if `x==undef`.
// Arguments:
//   x = value to check
// Example:
//   bool = is_def(undef);  // Returns: false
//   bool = is_def(false);  // Returns: true
//   bool = is_def(42);     // Returns: true
//   bool = is_def("foo");  // Returns: true
function is_def(x) = !is_undef(x);


// Function: is_str()
// Synopsis: Returns true if the argument is a string.
// Topics: Type Checking
// See Also: typeof(), is_type(), is_int(), is_def(), is_int()
// Usage:
//   bool = is_str(x);
// Description:
//   Returns true if `x` is a string.  A shortcut for `is_string()`.
// Arguments:
//   x = value to check
// Example:
//   bool = is_str(undef);  // Returns: false
//   bool = is_str(false);  // Returns: false
//   bool = is_str(42);     // Returns: false
//   bool = is_str("foo");  // Returns: true
function is_str(x) = is_string(x);


// Function: is_int()
// Alias: is_integer()
// Synopsis: Returns true if the argument is an integer.
// Topics: Type Checking
// See Also: typeof(), is_type(), is_str(), is_def()
// Usage:
//   bool = is_int(n);
//   bool = is_integer(n);
// Description:
//   Returns true if the given value is an integer (it is a number and it rounds to itself).  
// Arguments:
//   n = value to check
// Example:
//   bool = is_int(undef);  // Returns: false
//   bool = is_int(false);  // Returns: false
//   bool = is_int(42);     // Returns: true
//   bool = is_int("foo");  // Returns: false
function is_int(n) = is_finite(n) && n == round(n);
function is_integer(n) = is_finite(n) && n == round(n);


// Function: all_integer()
// Synopsis: Returns true if all of the numbers in the argument are integers.
// Topics: Type Checking
// See also: is_int(), typeof(), is_type()
// Usage:
//   bool = all_integer(x);
// Description:
//   If given a number, returns true if the number is a finite integer.
//   If given an empty list, returns false.  If given a non-empty list, returns
//   true if every item of the list is an integer.  Otherwise, returns false.
// Arguments:
//   x = The value to check.
// Example:
//   b = all_integer(true);  // Returns: false
//   b = all_integer("foo"); // Returns: false
//   b = all_integer(4);     // Returns: true
//   b = all_integer(4.5);   // Returns: false
//   b = all_integer([]);    // Returns: false
//   b = all_integer([3,4,5]);   // Returns: true
//   b = all_integer([3,4.2,5]); // Returns: false
//   b = all_integer([3,[4,7],5]); // Returns: false
function all_integer(x) =
    is_num(x)? is_int(x) :
    is_list(x)? (x != [] && [for (xx=x) if(!is_int(xx)) 1] == []) :
    false;


// Function: is_nan()
// Synopsis: Return true if the argument is "not a number".
// Topics: Type Checking
// See Also: typeof(), is_type(), is_str(), is_def(), is_int(), is_finite()
// Usage:
//   bool = is_nan(x);
// Description:
//   Returns true if a given value `x` is nan, a floating point value representing "not a number".
// Arguments:
//   x = value to check
// Example:
//   bool = is_nan(undef);  // Returns: false
//   bool = is_nan(false);  // Returns: false
//   bool = is_nan(42);     // Returns: false
//   bool = is_nan("foo");  // Returns: false
//   bool = is_nan(NAN);    // Returns: true
function is_nan(x) = (x!=x);


// Function: is_finite()
// Synopsis: Returns true if the argument is a finite number.
// Topics: Type Checking
// See Also: typeof(), is_type(), is_str(), is_def(), is_int(), is_nan()
// Usage:
//   bool = is_finite(x);
// Description:
//   Returns true if a given value `x` is a finite number.
// Arguments:
//   x = value to check
// Example:
//   bool = is_finite(undef);  // Returns: false
//   bool = is_finite(false);  // Returns: false
//   bool = is_finite(42);     // Returns: true
//   bool = is_finite("foo");  // Returns: false
//   bool = is_finite(NAN);    // Returns: false
//   bool = is_finite(INF);    // Returns: false
//   bool = is_finite(-INF);   // Returns: false
function is_finite(x) = is_num(x) && !is_nan(0*x);


// Function: is_range()
// Synopsis: Returns true if the argument is a range.
// Topics: Type Checking
// See Also: typeof(), is_type(), is_str(), is_def(), is_int()
// Usage:
//   bool = is_range(x);
// Description:
//   Returns true if its argument is a range
// Arguments:
//   x = value to check
// Example:
//   bool = is_range(undef);   // Returns: false
//   bool = is_range(false);   // Returns: false
//   bool = is_range(42);      // Returns: false
//   bool = is_range([3,4,5]); // Returns: false
//   bool = is_range("foo");   // Returns: false
//   bool = is_range([3:5]);   // Returns: true
function is_range(x) = !is_list(x) && is_finite(x[0]) && is_finite(x[1]) && is_finite(x[2]) ;


// Function: valid_range()
// Synopsis: Returns true if the argument is a valid range.
// Topics: Type Checking
// See Also: typeof(), is_type(), is_str(), is_def(), is_int(), is_range()
// Usage:
//   bool = valid_range(x);
// Description:
//   Returns true if its argument is a valid range (deprecated ranges excluded).
// Arguments:
//   x = value to check
// Example:
//   bool = is_range(undef);   // Returns: false
//   bool = is_range(false);   // Returns: false
//   bool = is_range(42);      // Returns: false
//   bool = is_range([3,4,5]); // Returns: false
//   bool = is_range("foo");   // Returns: false
//   bool = is_range([3:5]);   // Returns: true
//   bool = is_range([3:1]);   // Returns: false
function valid_range(x) = 
    is_range(x) 
    && ( x[1]>0 
         ? x[0]<=x[2]
         : ( x[1]<0 && x[0]>=x[2] ) );


// Function: is_func()
// Synopsis: Returns true if the argument is a function literal.
// Topics: Type Checking, Function Literals
// See also: is_type(), typeof()
// Usage:
//   bool = is_func(x);
// Description:
//   Returns true if OpenSCAD supports function literals, and the given item is one.
// Arguments:
//   x = The value to check
// Example:
//   f = function (a) a==2;
//   bool = is_func(f);  // Returns: true
function is_func(x) = version_num()>20210000 && is_function(x);


// Function: is_consistent()
// Synopsis: Returns true if the argument is a list with consistent structure and finite numerical data.
// Topics: Type Checking, Testing
// See Also: typeof(), is_type(), is_str(), is_def(), is_int(), is_range(), is_homogeneous()
// Usage:
//   bool = is_consistent(list, [pattern]);
// Description:
//   Tests whether input is a list of entries which all have the same list structure
//   and are filled with finite numerical data.  You can optionally specify a required 
//   list structure with the pattern argument.  
//   It returns `true` for the empty list regardless the value of the `pattern`.
// Arguments:
//   list = list to check
//   pattern = optional pattern required to match
// Example:
//   is_consistent([3,4,5]);              // Returns true
//   is_consistent([[3,4],[4,5],[6,7]]);  // Returns true
//   is_consistent([[3,4,5],[3,4]]);      // Returns false
//   is_consistent([[3,[3,4,[5]]], [5,[2,9,[9]]]]); // Returns true
//   is_consistent([[3,[3,4,[5]]], [5,[2,9,9]]]);   // Returns false
//   is_consistent([3,4,5], 0);            // Returns true
//   is_consistent([3,4,undef], 0);        // Returns false
//   is_consistent([[3,4],[4,5]], [1,1]);  // Returns true
//   is_consistent([[3,"a"],[4,true]], [1,undef]);  // Returns true
//   is_consistent([[3,4], 6, [4,5]], [1,1]);  // Returns false
//   is_consistent([[1,[3,4]], [4,[5,6]]], [1,[2,3]]);    // Returns true
//   is_consistent([[1,[3,INF]], [4,[5,6]]], [1,[2,3]]);  // Returns false
//   is_consistent([], [1,[2,3]]);                        // Returns true
function is_consistent(list, pattern) =
    is_list(list) 
    && (len(list)==0 
       || (let(pattern = is_undef(pattern) ? _list_pattern(list[0]): _list_pattern(pattern) )
          []==[for(entry=0*list) if (entry != pattern) entry]));

//Internal function
//Creates a list with the same structure of `list` with each of its elements replaced by 0.
function _list_pattern(list) =
  is_list(list) 
  ? [for(entry=list) is_list(entry) ? _list_pattern(entry) : 0]
  : 0;


// Function: same_shape()
// Synopsis: Returns true if the argument lists are numeric and of the same shape.
// Topics: Type Checking, Testing
// See Also: is_homogeneous(), is_consistent()
// Usage:
//   bool = same_shape(a,b);
// Description:
//   Tests whether the inputs `a` and `b` are both numeric and are the same shaped list.
// Example:
//   same_shape([3,[4,5]],[7,[3,4]]);   // Returns true
//   same_shape([3,4,5], [7,[3,4]]);    // Returns false
function same_shape(a,b) = is_def(b) && _list_pattern(a) == b*0;


// Function: is_bool_list()
// Synopsis: Returns true if the argument list contains only booleans.
// Topics: Boolean Testing
// See Also: is_homogeneous(), is_consistent()
// Usage:
//   check = is_bool_list(list,[length])
// Description:
//   Tests whether input is a list containing only booleans, and optionally checks its length.
// Arguments:
//   list = list to test
//   length = if given, list must be this length
function is_bool_list(list, length) =
     is_list(list) && (is_undef(length) || len(list)==length) && []==[for(entry=list) if (!is_bool(entry)) 1];


// Section: Boolean list testing

// Function: any()
// Synopsis: Returns true if any item in the argument list is true.
// Topics: Type Checking
// See Also: all(), num_true()
// Usage:
//   bool = any(l);
//   bool = any(l, func);   // Requires OpenSCAD 2021.01 or later.
// Requirements:
//   Requires OpenSCAD 2021.01 or later to use the `func` argument.
// Description:
//   Returns true if any item in list `l` evaluates as true.
//   If `func` is given then returns true if the function evaluates as true on any list entry. 
//   Items that evaluate as true include nonempty lists, nonempty strings, and nonzero numbers.
// Arguments:
//   l = The list to test for true items.
//   func = An optional function literal of signature (x), returning bool, to test each list item with.
// Example:
//   any([0,false,undef]);  // Returns false.
//   any([1,false,undef]);  // Returns true.
//   any([1,5,true]);       // Returns true.
//   any([[0,0], [0,0]]);   // Returns true.
//   any([[0,0], [1,0]]);   // Returns true.
function any(l, func) =
    assert(is_list(l), "The input is not a list." )
    assert(func==undef || is_func(func))
    is_func(func)
      ? _any_func(l, func)
      : _any_bool(l);

function _any_func(l, func, i=0, out=false) =
    i >= len(l) || out? out :
    _any_func(l, func, i=i+1, out=out || func(l[i]));

function _any_bool(l, i=0, out=false) =
    i >= len(l) || out? out :
    _any_bool(l, i=i+1, out=out || l[i]);


// Function: all()
// Synopsis: Returns true if all items in the argument list are true.
// Topics: Type Checking
// See Also: any(), num_true()
// Usage:
//   bool = all(l);
//   bool = all(l, func);   // Requires OpenSCAD 2021.01 or later.
// Requirements:
//   Requires OpenSCAD 2021.01 or later to use the `func` argument.
// Description:
//   Returns true if all items in list `l` evaluate as true.
//   If `func` is given then returns true if the function evaluates as true on all list etnries. 
//   Items that evaluate as true include nonempty lists, nonempty strings, and nonzero numbers.
// Arguments:
//   l = The list to test for true items.
//   func = An optional function literal of signature (x), returning bool, to test each list item with.
// Example:
//   test1 = all([0,false,undef]);  // Returns false.
//   test2 = all([1,false,undef]);  // Returns false.
//   test3 = all([1,5,true]);       // Returns true.
//   test4 = all([[0,0], [0,0]]);   // Returns true.
//   test5 = all([[0,0], [1,0]]);   // Returns true.
//   test6 = all([[1,1], [1,1]]);   // Returns true.
function all(l, func) =
    assert(is_list(l), "The input is not a list.")
    assert(func==undef || is_func(func))
    is_func(func)
      ? _all_func(l, func)
      : _all_bool(l);

function _all_func(l, func, i=0, out=true) =
    i >= len(l) || !out? out :
    _all_func(l, func, i=i+1, out=out && func(l[i]));

function _all_bool(l, i=0, out=true) =
    i >= len(l) || !out? out :
    _all_bool(l, i=i+1, out=out && l[i]);


// Function: num_true()
// Synopsis: Returns the number of true entries in the arguemnt list.
// Topics: Boolean Testing
// See Also: any(), all()
// Usage:
//   seq = num_true(l);
//   seq = num_true(l, func);  // Requires OpenSCAD 2021.01 or later.
// Requirements:
//   Requires OpenSCAD 2021.01 or later to use the `func=` argument.
// Description:
//   Returns the number of items in `l` that evaluate as true.  If `func` is given then counts
//   list entries where the function evaluates as true.  
//   Items that evaluate as true include nonempty lists, nonempty strings, and nonzero numbers.
// Arguments:
//   l = The list to test for true items.
//   func = An optional function literal of signature (x), returning bool, to test each list item with.
// Example:
//   num1 = num_true([0,false,undef]);  // Returns 0.
//   num2 = num_true([1,false,undef]);  // Returns 1.
//   num3 = num_true([1,5,false]);      // Returns 2.
//   num4 = num_true([1,5,true]);       // Returns 3.
//   num5 = num_true([[0,0], [0,0]]);   // Returns 2.
//   num6 = num_true([[], [1,0]]);      // Returns 1.
function num_true(l, func) = 
    assert(is_list(l))
    assert(func==undef || is_func(func))
    let(
        true_list = is_def(func)? [for(entry=l) if (func(entry)) 1]
                                : [for(entry=l) if (entry) 1]
    )
    len(true_list);



// Section: Handling `undef`s.


// Function: default()
// Synopsis: Returns a default value if the argument is 'undef', else returns the argument.
// Topics: Undef Handling
// See Also: first_defined(), one_defined(), num_defined()
// Usage:
//   val = default(val, dflt);
// Description:
//   Returns the value given as `v` if it is not `undef`.
//   Otherwise, returns the value of `dflt`.
// Arguments:
//   v = Value to pass through if not `undef`.
//   dflt = Value to return if `v` *is* `undef`.  Default: undef
function default(v,dflt=undef) = is_undef(v)? dflt : v;


// Function: first_defined()
// Synopsis: Returns the first value in the argument list that is not 'undef'.
// Topics: Undef Handling
// See Also: default(), one_defined(), num_defined(), any_defined(), all_defined()
// Usage:
//   val = first_defined(v, [recursive]);
// Description:
//   Returns the first item in the list that is not `undef`.
//   If all items are `undef`, or list is empty, returns `undef`.
// Arguments:
//   v = The list whose items are being checked.
//   recursive = If true, sublists are checked recursively for defined values.  The first sublist that has a defined item is returned.  Default: false
// Example:
//   val = first_defined([undef,7,undef,true]);  // Returns: 7
function first_defined(v,recursive=false,_i=0) =
    _i<len(v) && (
        is_undef(v[_i]) || (
            recursive &&
            is_list(v[_i]) &&
            is_undef(first_defined(v[_i],recursive=recursive))
        )
    )? first_defined(v,recursive=recursive,_i=_i+1) : v[_i];
    

// Function: one_defined()
// Synopsis: Returns the defined value in the argument list if only a single value is defined.
// Topics: Undef Handling
// See Also: default(), first_defined(), num_defined(), any_defined(), all_defined()
// Usage:
//   val = one_defined(vals, names, [dflt])
// Description:
//   Examines the input list `vals` and returns the entry which is not `undef`.
//   If more than one entry is not `undef` then an error is asserted, specifying
//   "Must define exactly one of" followed by the names in the `names` parameter.
//   If `dflt` is given, and all `vals` are `undef`, then the value in `dflt` is returned.
//   If `dflt` is *not* given, and all `vals` are `undef`, then an error is asserted.
// Arguments:
//   vals = The values to return the first one which is not `undef`.
//   names = A string with comma-separated names for the arguments whose values are passed in `vals`.
//   dflt = If given, the value returned if all `vals` are `undef`.
// Example:
//   length1 = one_defined([length,L,l], ["length","L","l"]);
//   length2 = one_defined([length,L,l], "length,L,l", dflt=1);

function one_defined(vals, names, dflt=_UNDEF) = 
    let(
        checkargs = is_list(names)? assert(len(vals) == len(names)) :
            is_string(names)? let(
                name_cnt = len([for (c=names) if (c==",") 1]) + 1
            ) assert(len(vals) == name_cnt) :
            assert(is_list(names) || is_string(names)) 0,
        ok = num_defined(vals)==1 || (dflt!=_UNDEF && num_defined(vals)==0)
    ) ok? default(first_defined(vals), dflt) :
    let(
        names = is_string(names) ? str_split(names,",") : names,
        defd = [for (i=idx(vals)) if (is_def(vals[i])) names[i]],
        msg = str(
            "Must define ",
            dflt==_UNDEF? "exactly" : "at most",
            " one of ",
            num_defined(vals) == 0 ? names : defd
        )
    ) assert(ok,msg);


// Function: num_defined()
// Synopsis: Returns the number of defined values in the the argument list.
// Topics: Undef Handling
// See Also: default(), first_defined(), one_defined(), any_defined(), all_defined()
// Usage:
//   cnt = num_defined(v);
// Description:
//   Counts how many items in list `v` are not `undef`.
// Example:
//   cnt = num_defined([3,7,undef,2,undef,undef,1]);  // Returns: 4
function num_defined(v) =
    len([for(vi=v) if(!is_undef(vi)) 1]);


// Function: any_defined()
// Synopsis: Returns true if any item in the argument list is not `undef`.
// Topics: Undef Handling
// See Also: default(), first_defined(), one_defined(), num_defined(), all_defined()
// Usage:
//   bool = any_defined(v, [recursive]);
// Description:
//   Returns true if any item in the given array is not `undef`.
// Arguments:
//   v = The list whose items are being checked.
//   recursive = If true, any sublists are evaluated recursively.  Default: false
// Example:
//   bool = any_defined([undef,undef,undef]);    // Returns: false
//   bool = any_defined([undef,42,undef]);       // Returns: true
//   bool = any_defined([34,42,87]);             // Returns: true
//   bool = any_defined([undef,undef,[undef]]);  // Returns: true
//   bool = any_defined([undef,undef,[undef]],recursive=true);  // Returns: false
//   bool = any_defined([undef,undef,[42]],recursive=true);     // Returns: true
function any_defined(v,recursive=false) =
    first_defined(v,recursive=recursive) != undef;


// Function: all_defined()
// Synopsis: Returns true if all items in the given array are defined.
// Topics: Undef Handling
// See Also: default(), first_defined(), one_defined(), num_defined(), all_defined()
// Usage:
//   bool = all_defined(v, [recursive]);
// Description:
//   Returns true if all items in the given array are not `undef`.
// Arguments:
//   v = The list whose items are being checked.
//   recursive = If true, any sublists are evaluated recursively.  Default: false
// Example:
//   bool = all_defined([undef,undef,undef]);    // Returns: false
//   bool = all_defined([undef,42,undef]);       // Returns: false
//   bool = all_defined([34,42,87]);             // Returns: true
//   bool = all_defined([23,34,[undef]]);        // Returns: true
//   bool = all_defined([23,34,[undef]],recursive=true);  // Returns: false
//   bool = all_defined([23,34,[42]],recursive=true);     // Returns: true
function all_defined(v,recursive=false) = 
    []==[for (x=v) if(is_undef(x)||(recursive && is_list(x) && !all_defined(x,recursive))) 0 ];



// Section: Undef Safe Arithmetic

// Function: u_add()
// Synopsis: Returns the sum of 2 numbers if both are defined, otherwise returns undef.
// Topics: Undef Handling
// See Also: u_sub(), u_mul(), u_div()
// Usage:
//   x = u_add(a, b);
// Description:
//   Adds `a` to `b`, returning the result, or undef if either value is `undef`.
//   This emulates the way undefs used to be handled in versions of OpenSCAD before 2020.
// Arguments:
//   a = First value.
//   b = Second value.
function u_add(a,b) = is_undef(a) || is_undef(b)? undef : a + b;


// Function: u_sub()
// Synopsis: Returns the difference of 2 numbers if both are defined, otherwise returns undef.
// Topics: Undef Handling
// See Also: u_add(), u_mul(), u_div()
// Usage:
//   x = u_sub(a, b);
// Description:
//   Subtracts `b` from `a`, returning the result, or undef if either value is `undef`.
//   This emulates the way undefs used to be handled in versions of OpenSCAD before 2020.
// Arguments:
//   a = First value.
//   b = Second value.
function u_sub(a,b) = is_undef(a) || is_undef(b)? undef : a - b;


// Function: u_mul()
// Synopsis: Returns the product of 2 numbers if both are defined, otherwise returns undef.
// Topics: Undef Handling
// See Also: u_add(), u_sub(), u_div()
// Usage:
//   x = u_mul(a, b);
// Description:
//   Multiplies `a` by `b`, returning the result, or undef if either value is `undef`.
//   This emulates the way undefs used to be handled in versions of OpenSCAD before 2020.
// Arguments:
//   a = First value.
//   b = Second value.
function u_mul(a,b) =
    is_undef(a) || is_undef(b)? undef :
    is_vector(a) && is_vector(b)? v_mul(a,b) :
    a * b;


// Function: u_div()
// Synopsis: Returns the quotient of 2 numbers if both are defined, otherwise returns undef.
// Topics: Undef Handling
// See Also: u_add(), u_sub(), u_mul()
// Usage:
//   x = u_div(a, b);
// Description:
//   Divides `a` by `b`, returning the result, or undef if either value is `undef`.
//   This emulates the way undefs used to be handled in versions of OpenSCAD before 2020.
// Arguments:
//   a = First value.
//   b = Second value.
function u_div(a,b) =
    is_undef(a) || is_undef(b)? undef :
    is_vector(a) && is_vector(b)? v_div(a,b) :
    a / b;




// Section: Processing Arguments to Functions and Modules


// Function: get_anchor()
// Synopsis: Returns the correct anchor from `anchor` and `center`.
// Topics: Argument Handling
// See Also: get_radius()
// Usage:
//   anchr = get_anchor(anchor,center,[uncentered],[dflt]);
// Description:
//   Calculated the correct anchor from `anchor` and `center`.  In order:
//   - If `center` is not `undef` and `center` evaluates as true, then `CENTER` (`[0,0,0]`) is returned.
//   - Otherwise, if `center` is not `undef` and `center` evaluates as false, then the value of `uncentered` is returned.
//   - Otherwise, if `anchor` is not `undef`, then the value of `anchor` is returned.
//   - Otherwise, the value of `dflt` is returned.
//   .
//   This ordering ensures that `center` will override `anchor`.
// Arguments:
//   anchor = The anchor name or vector.
//   center = If not `undef`, this overrides the value of `anchor`.
//   uncentered = The value to return if `center` is not `undef` and evaluates as false.  Default: BOTTOM
//   dflt = The default value to return if both `anchor` and `center` are `undef`.  Default: `CENTER`
// Example:
//   anchr1 = get_anchor(undef, undef, BOTTOM, TOP);  // Returns: [0, 0, 1] (TOP)
//   anchr2 = get_anchor(RIGHT, undef, BOTTOM, TOP);  // Returns: [1, 0, 0] (RIGHT)
//   anchr3 = get_anchor(undef, false, BOTTOM, TOP);  // Returns: [0, 0,-1] (BOTTOM)
//   anchr4 = get_anchor(RIGHT, false, BOTTOM, TOP);  // Returns: [0, 0,-1] (BOTTOM)
//   anchr5 = get_anchor(undef, true,  BOTTOM, TOP);  // Returns: [0, 0, 0] (CENTER)
//   anchr6 = get_anchor(RIGHT, true,  BOTTOM, TOP);  // Returns: [0, 0, 0] (CENTER)
function get_anchor(anchor,center,uncentered=BOT,dflt=CENTER) =
    !is_undef(center)? (center? CENTER : uncentered) :
    !is_undef(anchor)? anchor :
    dflt;


// Function: get_radius()
// Synopsis: Given various radii and diameters, returns the most specific radius.
// Topics: Argument Handling
// See Also: get_anchor()
// Usage:
//   r = get_radius([r1=], [r2=], [r=], [d1=], [d2=], [d=], [dflt=]);
// Description:
//   Given various radii and diameters, returns the most specific radius.  If a diameter is most
//   specific, returns half its value, giving the radius.  If no radii or diameters are defined,
//   returns the value of `dflt`.  Value specificity order is `r1`, `r2`, `d1`, `d2`, `r`, `d`,
//   then `dflt`.  Only one of `r1`, `r2`, `d1`, or `d2` can be defined at once, or else it errors
//   out, complaining about conflicting radius/diameter values.  
// Arguments:
//   ---
//   r1 = Most specific radius.
//   r2 = Second most specific radius.
//   r = Most general radius.
//   d1 = Most specific diameter.
//   d2 = Second most specific diameter.
//   d = Most general diameter.
//   dflt = Value to return if all other values given are `undef`.
// Example:
//   r = get_radius(r1=undef, r=undef, dflt=undef);  // Returns: undef
//   r = get_radius(r1=undef, r=undef, dflt=1);      // Returns: 1
//   r = get_radius(r1=undef, r=6, dflt=1);          // Returns: 6
//   r = get_radius(r1=7, r=6, dflt=1);              // Returns: 7
//   r = get_radius(r1=undef, r2=8, r=6, dflt=1);    // Returns: 8
//   r = get_radius(r1=undef, r2=8, d=6, dflt=1);    // Returns: 8
//   r = get_radius(r1=undef, d=6, dflt=1);          // Returns: 3
//   r = get_radius(d1=7, d=6, dflt=1);              // Returns: 3.5
//   r = get_radius(d1=7, d2=8, d=6, dflt=1);        // Returns: 3.5
//   r = get_radius(d1=undef, d2=8, d=6, dflt=1);    // Returns: 4
//   r = get_radius(r1=8, d=6, dflt=1);              // Returns: 8
function get_radius(r1, r2, r, d1, d2, d, dflt) = 
    assert(num_defined([r1,d1,r2,d2])<2, "Conflicting or redundant radius/diameter arguments given.")
    assert(num_defined([r,d])<2, "Conflicting or redundant radius/diameter arguments given.")
    let(
        rad = !is_undef(r1) ?  r1 
            : !is_undef(d1) ?  d1/2
            : !is_undef(r2) ?  r2
            : !is_undef(d2) ?  d2/2
            : !is_undef(r)  ?  r
            : !is_undef(d)  ?  d/2
            : dflt
    )
    assert(is_undef(dflt) || is_finite(rad) || is_vector(rad), "Invalid radius." )
    rad;


// Function: scalar_vec3()
// Synopsis: Expands a scalar or a list with length less than 3 to a length 3 vector. 
// Topics: Argument Handling
// See Also: get_anchor(), get_radius(), force_list()
// Usage:
//   vec = scalar_vec3(v, [dflt]);
// Description:
//   This is expands a scalar or a list with length less than 3 to a length 3 vector in the
//   same way that OpenSCAD expands short vectors in some contexts, e.g. cube(10) or rotate([45,90]).  
//   If `v` is a scalar, and `dflt==undef`, returns `[v, v, v]`.
//   If `v` is a scalar, and `dflt!=undef`, returns `[v, dflt, dflt]`.
//   if `v` is a list of length 3 or more then returns `v`
//   If `v` is a list and dflt is defined, returns a length 3 list by padding with `dflt`
//   If `v` is a list and dflt is undef, returns a length 3 list by padding with 0
//   If `v` is `undef`, returns `undef`.
// Arguments:
//   v = Value to return vector from.
//   dflt = Default value to set empty vector parts from.
// Example:
//   vec = scalar_vec3(undef);      // Returns: undef
//   vec = scalar_vec3(10);         // Returns: [10,10,10]
//   vec = scalar_vec3(10,1);       // Returns: [10,1,1]
//   vec = scalar_vec3([10,10],1);  // Returns: [10,10,1]
//   vec = scalar_vec3([10,10]);    // Returns: [10,10,0]
//   vec = scalar_vec3([10]);       // Returns: [10,0,0]
function scalar_vec3(v, dflt) =
    is_undef(v)? undef :
    is_list(v)? [for (i=[0:2]) default(v[i], default(dflt, 0))] :
    !is_undef(dflt)? [v,dflt,dflt] : [v,v,v];

// Function: segs()
// Synopsis: Returns the number of sides for a circle given `$fn`, `$fa`, and `$fs`.
// Topics: Geometry
// See Also: circle(), cyl()
// Usage:
//   sides = segs(r);
// Description:
//   Calculate the standard number of sides OpenSCAD would give a circle based on `$fn`, `$fa`, and `$fs`.
// Arguments:
//   r = Radius of circle to get the number of segments for.
// Example:
//   $fn=12; sides=segs(10);  // Returns: 12
//   $fa=2; $fs=3; sides=segs(10);  // Returns: 21
function segs(r) = 
    $fn>0? ($fn>3? $fn : 3) :
    let( r = is_finite(r)? r : 0 )
    ceil(max(5, min(360/$fa, abs(r)*2*PI/$fs)));


// Module: no_children()
// Synopsis: Assert that the calling module does not support children.
// Topics: Error Checking
// See Also: no_function(), no_module(), req_children()
// Usage:
//   no_children($children);
// Description:
//   Assert that the calling module does not support children.  Prints an error message to this effect and fails if children are present,
//   as indicated by its argument.
// Arguments:
//   $children = number of children the module has.  
// Example:
//   module foo() {
//       no_children($children);
//   }
module no_children(count) {
  assert($children==0, "Module no_children() does not support child modules");
  if ($parent_modules>0) {
      assert(count==0, str("Module ",parent_module(1),"() does not support child modules"));
  }
}


// Module: req_children()
// Synopsis: Assert that the calling module requires children.
// Topics: Error Checking
// See Also: no_function(), no_module()
// Usage:
//   req_children($children);
// Description:
//   Assert that the calling module requires children.  Prints an error message and fails if no
//   children are present as indicated by its argument.
// Arguments:
//   $children = number of children the module has.  
// Example:
//   module foo() {
//       req_children($children);
//   }
module req_children(count) {
  assert($children==0, "Module no_children() does not support child modules");
  if ($parent_modules>0) {
      assert(count>0, str("Module ",parent_module(1),"() requires children"));
  }
}


// Function: no_function()
// Synopsis: Assert that the argument exists only as a module and not as a function.
// Topics: Error Checking
// See Also: no_children(), no_module()
// Usage:
//   dummy = no_function(name)
// Description:
//   Asserts that the function, "name", only exists as a module.
// Example:
//   x = no_function("foo");
function no_function(name) =
   assert(false,str("You called ",name,"() as a function, but it is available only as a module"));


// Module: no_module()
// Synopsis: Assert that the argument exists only as a function and not as a module.
// Topics: Error Checking
// See Also: no_children(), no_function()
// Usage:
//   no_module();
// Description:
//   Asserts that the called module exists only as a function.
// Example:
//   module foo() { no_module(); }
module no_module() {
    assert(false, str("You called ",parent_module(1),"() as a module but it is available only as a function"));
}    
  

// Module: deprecate()
// Synopsis: Display a console note that a module is deprecated and suggest a replacement.
// Topics: Error Checking
// See Also: no_function(), no_module()
// Usage:
//   deprecate(new_name);
// Description:
//   Display info that the current module is deprecated and you should switch to a new name
// Arguments:
//   new_name = name of the new module that replaces the old one
module deprecate(new_name)
{
   echo(str("***** Module ",parent_module(1),"() has been replaced by ",new_name,"() and will be removed in a future version *****"));
}   



// Module: echo_viewport()
// Synopsis: Display the current viewport parameters. 
// Usage:
//   echo_viewport();
// Description:
//   Display the current viewport parameters so that they can be pasted into examples for the wiki.
//   The viewport should have a 4:3 aspect ratio to ensure proper framing of the object.  

module echo_viewport()
{
    echo(format("VPR=[{:.2f},{:.2f},{:.2f}],VPD={:.2f},VPT=[{:.2f},{:.2f},{:.2f}]", [each $vpr, $vpd, each $vpt]));
}    



// Section: Testing Helpers


function _valstr(x) =
    is_string(x)? str("\"",str_replace_char(x, "\"", "\\\""),"\"") :
    is_list(x)? str("[",str_join([for (xx=x) _valstr(xx)],","),"]") :
    is_num(x) && x==floor(x)? format_int(x) :
    is_finite(x)? format_float(x,12) : x;


// Module: assert_approx()
// Synopsis: Assert that a value is approximately what was expected.
// Topics: Error Checking, Debugging
// See Also: no_children(), no_function(), no_module(), assert_equal()
// Usage:
//   assert_approx(got, expected, [info]);
// Description:
//   Tests if the value gotten is what was expected, plus or minus 1e-9.  If not, then
//   the expected and received values are printed to the console and
//   an assertion is thrown to stop execution.
//   Returns false if both 'got' and 'expected' are 'nan'.
// Arguments:
//   got = The value actually received.
//   expected = The value that was expected.
//   info = Extra info to print out to make the error clearer.
// Example:
//   assert_approx(1/3, 0.333333333333333, str("number=",1,", denom=",3));
module assert_approx(got, expected, info) {
    no_children($children);
    if (!approx(got, expected)) {
        echo();
        echo(str("EXPECT: ", _valstr(expected)));
        echo(str("GOT   : ", _valstr(got)));
        if (same_shape(got, expected)) {
            echo(str("DELTA : ", _valstr(got - expected)));
        }
        if (is_def(info)) {
            echo(str("INFO  : ", _valstr(info)));
        }
        assert(approx(got, expected));
    }
}


// Module: assert_equal()
// Synopsis: Assert that a value is expected.
// See Also: no_children(), no_function(), no_module(), assert_approx()
// Topics: Error Checking, Debugging
// Usage:
//   assert_equal(got, expected, [info]);
// Description:
//   Tests if the value gotten is what was expected.  If not, then the expected and received values
//   are printed to the console and an assertion is thrown to stop execution.
//   Returns true if both 'got' and 'expected' are 'nan'.
// Arguments:
//   got = The value actually received.
//   expected = The value that was expected.
//   info = Extra info to print out to make the error clearer.
// Example:
//   assert_equal(3*9, 27, str("a=",3,", b=",9));
module assert_equal(got, expected, info) {
    no_children($children);
    if (got != expected || (is_nan(got) && is_nan(expected))) {
        echo();
        echo(str("EXPECT: ", _valstr(expected)));
        echo(str("GOT   : ", _valstr(got)));
        if (same_shape(got, expected)) {
            echo(str("DELTA : ", _valstr(got - expected)));
        }
        if (is_def(info)) {
            echo(str("INFO  : ", _valstr(info)));
        }
        assert(got == expected);
    }
}


// Module: shape_compare()
// Synopsis: Compares two child shapes.
// SynTags: Geom
// Topics: Error Checking, Debugging, Testing
// See Also: assert_approx(), assert_equal()
// Usage:
//   shape_compare([eps]) {TEST_SHAPE; EXPECTED_SHAPE;}
// Description:
//   Compares two child shapes, returning empty geometry if they are very nearly the same shape and size.
//   Returns the differential geometry if they are not quite the same shape and size.
// Arguments:
//   eps = The surface of the two shapes must be within this size of each other.  Default: 1/1024
// Example:
//   $fn=36;
//   shape_compare() {
//       sphere(d=100);
//       rotate_extrude() right_half(planar=true) circle(d=100);
//   }
module shape_compare(eps=1/1024) {
    assert($children==2,"Must give exactly two children");
    union() {
        difference() {
            children(0);
            if (eps==0) {
                children(1);
            } else {
                minkowski() {
                    children(1);
                    spheroid(r=eps, style="octa");
                }
            }
        }
        difference() {
            children(1);
            if (eps==0) {
                children(0);
            } else {
                minkowski() {
                    children(0);
                    spheroid(r=eps, style="octa");
                }
            }
        }
    }
}


// Section: C-Style For Loop Helpers
//   You can use a list comprehension with a C-style for loop to iteratively make a calculation.
//   .
//   The syntax is: `[for (INIT; CONDITION; NEXT) RETVAL]` where:
//   - INIT is zero or more `let()` style assignments that are evaluated exactly one time, before the first loop.
//   - CONDITION is an expression evaluated at the start of each loop.  If true, continues with the loop.
//   - RETVAL is an expression that returns a list item for each loop.
//   - NEXT is one or more `let()` style assignments that is evaluated at the end of each loop.
//   .
//   Since the INIT phase is only run once, and the CONDITION and RETVAL expressions cannot update
//   variables, that means that only the NEXT phase can be used for iterative calculations.
//   Unfortunately, the NEXT phase runs *after* the RETVAL expression, which means that you need
//   to run the loop one extra time to return the final value.  This tends to make the loop code
//   look rather ugly.  The `looping()`, `loop_while()` and `loop_done()` functions
//   can make this somewhat more legible.
//   .
//   ```openscad
//   function flat_sum(l) = [
//       for (
//           i = 0,
//           total = 0,
//           state = 0;
//           
//           looping(state);
//           
//           state = loop_while(state, i < len(l)),
//           total = total +
//               loop_done(state) ? 0 :
//               let( x = l[i] )
//               is_list(x) ? flat_sum(x) : x,
//           i = i + 1
//       ) if (loop_done(state)) total;
//   ].x;
//   ```


// Function: looping()
// Synopsis: Returns true if the argument indicates the current C-style loop should continue.
// Topics: Iteration
// See Also: loop_while(), loop_done()
// Usage:
//   bool = looping(state);
// Description:
//   Returns true if the `state` value indicates the current loop should continue.  This is useful
//   when using C-style for loops to iteratively calculate a value.  Used with `loop_while()` and
//   `loop_done()`.  See [Looping Helpers](utility.scad#section-c-style-for-loop-helpers) for an example.
// Arguments:
//   state = The loop state value.
function looping(state) = state < 2;


// Function: loop_while()
// Synopsis: Returns true if both arguments indicate the current C-style loop should continue.
// Topics: Iteration
// See Also: looping(), loop_done()
// Usage:
//   state = loop_while(state, continue);
// Description:
//   Given the current `state`, and a boolean `continue` that indicates if the loop should still be
//   continuing, returns the updated state value for the the next loop.  This is useful when using
//   C-style for loops to iteratively calculate a value.  Used with `looping()` and `loop_done()`.
//   See [Looping Helpers](utility.scad#section-c-style-for-loop-helpers) for an example.
// Arguments:
//   state = The loop state value.
//   continue = A boolean value indicating whether the current loop should progress.
function loop_while(state, continue) =
    state > 0 ? 2 :
    continue ? 0 : 1;


// Function: loop_done()
// Synopsis: Returns true if the argument indicates the current C-style loop is finishing.
// Topics: Iteration
// See Also: looping(), loop_while()
// Usage:
//   bool = loop_done(state);
// Description:
//   Returns true if the `state` value indicates the loop is finishing.  This is useful when using
//   C-style for loops to iteratively calculate a value.  Used with `looping()` and `loop_while()`.
//   See [Looping Helpers](utility.scad#section-c-style-for-loop-helpers) for an example.
// Arguments:
//   state = The loop state value.
function loop_done(state) = state > 0;


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
