//////////////////////////////////////////////////////////////////////
// LibFile: math.scad
//   Math helper functions.
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Math Constants

PHI = (1+sqrt(5))/2;  // The golden ratio phi.

EPSILON = 1e-9;  // A really small value useful in comparing FP numbers.  ie: abs(a-b)<EPSILON


// Section: Simple Calculations

// Function: quant()
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding to the nearest multiple.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
function quant(x,y) = floor(x/y+0.5)*y;


// Function: quantdn()
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding down to the previous multiple.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
function quantdn(x,y) = floor(x/y)*y;


// Function: quantup()
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding up to the next multiple.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
function quantup(x,y) = ceil(x/y)*y;


// Function: constrain()
// Usage:
//   constrain(v, minval, maxval);
// Description:
//   Constrains value to a range of values between minval and maxval, inclusive.
// Arguments:
//   v = value to constrain.
//   minval = minimum value to return, if out of range.
//   maxval = maximum value to return, if out of range.
function constrain(v, minval, maxval) = min(maxval, max(minval, v));


// Function: approx()
// Usage:
//   approx(a,b,[eps])
// Description:
//   Compares two numbers or vectors, and returns true if they are closer than `eps` to each other.
// Arguments:
//   a = First value.
//   b = Second value.
//   eps = The maximum allowed difference between `a` and `b` that will return true.
function approx(a,b,eps=EPSILON) = let(c=a-b) (is_num(c)? abs(c) : norm(c)) <= eps;


// Function: min_index()
// Usage:
//   min_index(vals);
// Description:
//   Returns the index of the minimal value in the given list.
function min_index(vals, _minval, _minidx, _i=0) =
	_i>=len(vals)? _minidx :
	min_index(
		vals,
		((_minval == undef || vals[_i] < _minval)? vals[_i] : _minval),
		((_minval == undef || vals[_i] < _minval)? _i : _minidx),
		_i+1
	);


// Function: max_index()
// Usage:
//   max_index(vals);
// Description:
//   Returns the index of the maximum value in the given list.
function max_index(vals, _maxval, _maxidx, _i=0) =
	_i>=len(vals)? _maxidx :
	max_index(
		vals,
		((_maxval == undef || vals[_i] > _maxval)? vals[_i] : _maxval),
		((_maxval == undef || vals[_i] > _maxval)? _i : _maxidx),
		_i+1
	);


// Function: posmod()
// Usage:
//   posmod(x,m)
// Description:
//   Returns the positive modulo `m` of `x`.  Value returned will be in the range 0 ... `m`-1.
//   This if useful for normalizing angles to 0 ... 360.
// Arguments:
//   x = The value to constrain.
//   m = Modulo value.
function posmod(x,m) = (x%m+m)%m;


// Function: modrange()
// Usage:
//   modrange(x, y, m, [step])
// Description:
//   Returns a normalized list of values from `x` to `y`, by `step`, modulo `m`.  Wraps if `x` > `y`.
// Arguments:
//   x = The start value to constrain.
//   y = The end value to constrain.
//   m = Modulo value.
//   step = Step by this amount.
// Examples:
//   modrange(90,270,360, step=45);   // Outputs [90,135,180,225,270]
//   modrange(270,90,360, step=45);   // Outputs [270,315,0,45,90]
//   modrange(90,270,360, step=-45);  // Outputs [90,45,0,315,270]
//   modrange(270,90,360, step=-45);  // Outputs [270,225,180,135,90]
function modrange(x, y, m, step=1) =
	let(
		a = posmod(x, m),
		b = posmod(y, m),
		c = step>0? (a>b? b+m : b) : (a<b? b-m : b)
	) [for (i=[a:step:c]) (i%m+m)%m];


// Function: sqr()
// Usage:
//   sqr(x);
// Description: Returns the square of the given number.
// Examples:
//   sqr(3);   // Returns: 9
//   sqr(-4);  // Returns: 16
function sqr(x) = x*x;


// Function: gaussian_rand()
// Usage:
//   gaussian_rand(mean, stddev)
// Description:
//   Returns a random number with a gaussian/normal distribution.
// Arguments:
//   mean = The average random number returned.
//   stddev = The standard deviation of the numbers to be returned.
function gaussian_rand(mean, stddev) = let(s=rands(0,1,2)) mean + stddev*sqrt(-2*ln(s.x))*cos(360*s.y);


// Function: log_rand()
// Usage:
//   log_rand(minval, maxval, factor);
// Description:
//   Returns a single random number, with a logarithmic distribution.
// Arguments:
//   minval = Minimum value to return.
//   maxval = Maximum value to return.  `minval` <= X < `maxval`.
//   factor = Log factor to use.  Values of X are returned `factor` times more often than X+1.
function log_rand(minval, maxval, factor) = -ln(1-rands(1-1/pow(factor,minval), 1-1/pow(factor,maxval), 1)[0])/ln(factor);


// Function: segs()
// Description:
//   Calculate the standard number of sides OpenSCAD would give a circle based on `$fn`, `$fa`, and `$fs`.
// Arguments:
//   r = Radius of circle to get the number of segments for.
function segs(r) =
	$fn>0? ($fn>3? $fn : 3) :
	ceil(max(5, min(360/$fa, abs(r)*2*PI/$fs)));


// Function: lerp()
// Description: Interpolate between two values or vectors.
// Arguments:
//   a = First value.
//   b = Second value.
//   u = The proportion from `a` to `b` to calculate.  Valid range is 0.0 to 1.0, inclusive.
function lerp(a,b,u) = (1-u)*a + u*b;


// Function: hypot()
// Description: Calculate hypotenuse length of a 2D or 3D triangle.
// Arguments:
//   x = Length on the X axis.
//   y = Length on the Y axis.
//   z = Length on the Z axis.
function hypot(x,y,z=0) = norm([x,y,z]);


// Function: sinh()
// Description: Takes a value `x`, and returns the hyperbolic sine of it.
function sinh(x) = (exp(x)-exp(-x))/2;


// Function: cosh()
// Description: Takes a value `x`, and returns the hyperbolic cosine of it.
function cosh(x) = (exp(x)+exp(-x))/2;


// Function: tanh()
// Description: Takes a value `x`, and returns the hyperbolic tangent of it.
function tanh(x) = sinh(x)/cosh(x);


// Function: asinh()
// Description: Takes a value `x`, and returns the inverse hyperbolic sine of it.
function asinh(x) = ln(x+sqrt(x*x+1));


// Function: acosh()
// Description: Takes a value `x`, and returns the inverse hyperbolic cosine of it.
function acosh(x) = ln(x+sqrt(x*x-1));


// Function: atanh()
// Description: Takes a value `x`, and returns the inverse hyperbolic tangent of it.
function atanh(x) = ln((1+x)/(1-x))/2;


// Function: sum()
// Description:
//   Returns the sum of all entries in the given array.
//   If passed an array of vectors, returns a vector of sums of each part.
// Arguments:
//   v = The vector to get the sum of.
// Example:
//   sum([1,2,3]);  // returns 6.
//   sum([[1,2,3], [3,4,5], [5,6,7]]);  // returns [9, 12, 15]
function sum(v, i=0, tot=undef) = i>=len(v)? tot : sum(v, i+1, ((tot==undef)? v[i] : tot+v[i]));


// Function: sum_of_squares()
// Description:
//   Returns the sum of the square of each element of a vector.
// Arguments:
//   v = The vector to get the sum of.
// Example:
//   sum_of_squares([1,2,3]);  // returns 14.
function sum_of_squares(v, i=0, tot=0) = sum(vmul(v,v));


// Function: sum_of_sines()
// Usage:
//   sum_of_sines(a,sines)
// Description:
//   Gives the sum of a series of sines, at a given angle.
// Arguments:
//   a = Angle to get the value for.
//   sines = List of [amplitude, frequency, offset] items, where the frequency is the number of times the cycle repeats around the circle.
function sum_of_sines(a, sines) =
	sum([
		for (s = sines) let(
			ss=point3d(s),
			v=ss.x*sin(a*ss.y+ss.z)
		) v
	]);


// Function: mean()
// Description:
//   Returns the mean of all entries in the given array.
//   If passed an array of vectors, returns a vector of mean of each part.
// Arguments:
//   v = The list of values to get the mean of.
// Example:
//   mean([2,3,4]);  // returns 3.
//   mean([[1,2,3], [3,4,5], [5,6,7]]);  // returns [3, 4, 5]
function mean(v) = sum(v)/len(v);


// Section: Comparisons and Logic


// Function: compare_vals()
// Usage:
//   compare_vals(a, b);
// Description:
//   Compares two values.  Lists are compared recursively.
//   Results are undefined if the two values are not of similar types.
// Arguments:
//   a = First value to compare.
//   b = Second value to compare.
function compare_vals(a, b) =
	(a==b)? 0 :
	(a==undef)? -1 :
	(b==undef)? 1 :
	((a==[] || a=="" || a[0]!=undef) && (b==[] || b=="" || b[0]!=undef))? (
		compare_lists(a, b)
	) : (a<b)? -1 :
	(a>b)? 1 : 0;


// Function: compare_lists()
// Usage:
//   compare_lists(a, b)
// Description:
//   Compare contents of two lists.
//   Returns <0 if `a`<`b`.
//   Returns 0 if `a`==`b`.
//   Returns >0 if `a`>`b`.
//   Results are undefined if elements are not of similar types.
// Arguments:
//   a = First list to compare.
//   b = Second list to compare.
function compare_lists(a, b, n=0) =
	let(
		// This curious construction enables tail recursion optimization.
		cmp = (a==b)? 0 :
			(len(a)<=n)? -1 :
			(len(b)<=n)? 1 :
			(a==a[n] || b==b[n])? (
				a<b? -1 : a>b? 1 : 0
			) : compare_vals(a[n], b[n])
	)
	(cmp != 0 || a==b)? cmp :
	compare_lists(a, b, n+1);


// Function: any()
// Description:
//   Returns true if any item in list `l` evaluates as true.
//   If `l` is a lists of lists, `any()` is applied recursively to each sublist.
// Arguments:
//   l = The list to test for true items.
// Example:
//   any([0,false,undef]);  // Returns false.
//   any([1,false,undef]);  // Returns true.
//   any([1,5,true]);       // Returns true.
//   any([[0,0], [0,0]]);   // Returns false.
//   any([[0,0], [1,0]]);   // Returns true.
function any(l, i=0, succ=false) =
	(i>=len(l) || succ)? succ :
	any(
		l, i=i+1, succ=(
			is_list(l[i])? any(l[i]) :
			!(!l[i])
		)
	);


// Function: all()
// Description:
//   Returns true if all items in list `l` evaluate as true.
//   If `l` is a lists of lists, `all()` is applied recursively to each sublist.
// Arguments:
//   l = The list to test for true items.
// Example:
//   all([0,false,undef]);  // Returns false.
//   all([1,false,undef]);  // Returns false.
//   all([1,5,true]);       // Returns true.
//   all([[0,0], [0,0]]);   // Returns false.
//   all([[0,0], [1,0]]);   // Returns false.
//   all([[1,1], [1,1]]);   // Returns true.
function all(l, i=0, fail=false) =
	(i>=len(l) || fail)? (!fail) :
	all(
		l, i=i+1, fail=(
			is_list(l[i])? !all(l[i]) :
			!l[i]
		)
	);


// Function: count_true()
// Usage:
//   count_true(l)
// Description:
//   Returns the number of items in `l` that evaluate as true.
//   If `l` is a lists of lists, this is applied recursively to each
//   sublist.  Returns the total count of items that evaluate as true
//   in all recursive sublists.
// Arguments:
//   l = The list to test for true items.
//   nmax = If given, stop counting if `nmax` items evaluate as true.
// Example:
//   count_true([0,false,undef]);  // Returns 0.
//   count_true([1,false,undef]);  // Returns 1.
//   count_true([1,5,false]);      // Returns 2.
//   count_true([1,5,true]);       // Returns 3.
//   count_true([[0,0], [0,0]]);   // Returns 0.
//   count_true([[0,0], [1,0]]);   // Returns 1.
//   count_true([[1,1], [1,1]]);   // Returns 4.
//   count_true([[1,1], [1,1]], nmax=3);  // Returns 3.
function count_true(l, nmax=undef, i=0, cnt=0) =
	(i>=len(l) || (nmax!=undef && cnt>=nmax))? cnt :
	count_true(
		l=l, nmax=nmax, i=i+1, cnt=cnt+(
			is_list(l[i])? count_true(l[i], nmax=nmax-cnt) :
			(l[i]? 1 : 0)
		)
	);


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
