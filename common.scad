//////////////////////////////////////////////////////////////////////
// LibFile: common.scad
//   Common functions used in argument processing.
//   To use, include this line at the top of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Type handling helpers.


// Function: typeof()
// Usage:
//   typ = typeof(x);
// Description:
//   Returns a string representing the type of the value.  One of "undef", "boolean", "number", "string", "list", or "range"
function typeof(x) =
	is_undef(x)? "undef" :
	is_bool(x)? "boolean" :
	is_num(x)? "number" :
	is_string(x)? "string" :
	is_list(x)? "list" :
	"range";


// Function: is_type()
// Usage:
//   b = is_type(x, types);
// Description:
//   Returns true if the type of the value `x` is one of those given as strings in the list `types`. 
//   Valid types are "undef", "boolean", "number", "string", "list", or "range"
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
// Usage:
//   is_def(x)
// Description:
//   Returns true if `x` is not `undef`.  False if `x==undef`.
function is_def(x) = !is_undef(x);


// Function: is_str()
// Usage:
//   is_str(x)
// Description:
//   Returns true if `x` is a string.  A shortcut for `is_string()`.
function is_str(x) = is_string(x);


// Section: Handling `undef`s.


// Function: default()
// Description:
//   Returns the value given as `v` if it is not `undef`.
//   Otherwise, returns the value of `dflt`.
// Arguments:
//   v = Value to pass through if not `undef`.
//   dflt = Value to return if `v` *is* `undef`.
function default(v,dflt=undef) = is_undef(v)? dflt : v;


// Function: first_defined()
// Description:
//   Returns the first item in the list that is not `undef`.
//   If all items are `undef`, or list is empty, returns `undef`.
// Arguments:
//   v = The list whose items are being checked.
//   recursive = If true, sublists are checked recursively for defined values.  The first sublist that has a defined item is returned.
function first_defined(v,recursive=false,_i=0) =
	_i<len(v) && (
		is_undef(v[_i]) || (
			recursive &&
			is_list(v[_i]) &&
			is_undef(first_defined(v[_i],recursive=recursive))
		)
	)? first_defined(v,recursive=recursive,_i=_i+1) : v[_i];


// Function: num_defined()
// Description: Counts how many items in list `v` are not `undef`.
function num_defined(v,_i=0,_cnt=0) = _i>=len(v)? _cnt : num_defined(v,_i+1,_cnt+(is_undef(v[_i])? 0 : 1));


// Function: any_defined()
// Description:
//   Returns true if any item in the given array is not `undef`.
// Arguments:
//   v = The list whose items are being checked.
//   recursive = If true, any sublists are evaluated recursively.
function any_defined(v,recursive=false) = first_defined(v,recursive=recursive) != undef;


// Function: all_defined()
// Description:
//   Returns true if all items in the given array are not `undef`.
// Arguments:
//   v = The list whose items are being checked.
//   recursive = If true, any sublists are evaluated recursively.
function all_defined(v,recursive=false) = max([for (x=v) is_undef(x)||(recursive&&is_list(x)&&!all_defined(x))? 1 : 0])==0;


// Section: Argument Helpers


// Function: get_radius()
// Usage:
//   get_radius([r1], [r2], [r], [d1], [d2], [d], [dflt]);
// Description:
//   Given various radii and diameters, returns the most specific radius.
//   If a diameter is most specific, returns half its value, giving the radius.
//   If no radii or diameters are defined, returns the value of dflt.
//   Value specificity order is r1, r2, d1, d2, r, d, then dflt
//   Only one of `r1`, `r2`, `d1`, or `d2` can be defined at once, or else it
//   errors out, complaining about conflicting radius/diameter values.
//   Only one of `r` or `d` can be defined at once, or else it errors out,
//   complaining about conflicting radius/diameter values.
// Arguments:
//   r1 = Most specific radius.
//   d1 = Most specific diameter.
//   r2 = Second most specific radius.
//   d2 = Second most specific diameter.
//   r = Most general radius.
//   d = Most general diameter.
//   dflt = Value to return if all other values given are `undef`.
function get_radius(r1=undef, r2=undef, r=undef, d1=undef, d2=undef, d=undef, dflt=undef) = (
	!is_undef(r1)? assert(is_undef(r2)&&is_undef(d1)&&is_undef(d2), "Conflicting or redundant radius/diameter arguments given.") r1 :
	!is_undef(r2)? assert(is_undef(d1)&&is_undef(d2), "Conflicting or redundant radius/diameter arguments given.") r2 :
	!is_undef(d1)? d1/2 :
	!is_undef(d2)? d2/2 :
	!is_undef(r)? assert(is_undef(d), "Conflicting or redundant radius/diameter arguments given.") r :
	!is_undef(d)? d/2 :
	dflt
);

// Function: get_height()
// Usage:
//   get_height([h],[l],[height],[dflt])
// Description:
//   Given several different parameters for height check that height is not multiply defined
//   and return a single value.  If the three values `l`, `h`, and `height` are all undefined
//   then return the value `dflt`, if given, or undef otherwise.
// Arguments:
//   l = l.
//   h = h.
//   height = height.
//   dflt = Value to return if other values are `undef`. 
function get_height(h=undef,l=undef,height=undef,dflt=undef) =
    assert(num_defined([h,l,height])<=1,"You must specify only one of `l`, `h`, and `height`")
    first_defined([h,l,height,dflt]);


// Function: scalar_vec3()
// Usage:
//   scalar_vec3(v, [dflt]);
// Description:
//   If `v` is a scalar, and `dflt==undef`, returns `[v, v, v]`.
//   If `v` is a scalar, and `dflt!=undef`, returns `[v, dflt, dflt]`.
//   If `v` is a vector, returns the first 3 items, with any missing values replaced by `dflt`.
//   If `v` is `undef`, returns `undef`.
// Arguments:
//   v = Value to return vector from.
//   dflt = Default value to set empty vector parts from.
function scalar_vec3(v, dflt=undef) =
	is_undef(v)? undef :
	is_list(v)? [for (i=[0:2]) default(v[i], default(dflt, 0))] :
	!is_undef(dflt)? [v,dflt,dflt] : [v,v,v];


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
