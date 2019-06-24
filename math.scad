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
//   min_index(vals,[all]);
// Description:
//   Returns the index of the first occurrence of the mainimum value in the given list. 
//   If `all` is true then returns a list of all indices where the minimum value occurs.
// Arguments:
//   vals = vector of values
//   all = set to true to return indices of all occurences of the minimum.  Default: false
function min_index(vals, all=false) =
        all ? search(min(vals),vals,0) : search(min(vals), vals)[0];

// Function: max_index()
// Usage:
//   max_index(vals,[all]);
// Description:
//   Returns the index of the first occurrence of the maximum value in the given list. 
//   If `all` is true then returns a list of all indices where the maximum value occurs.
// Arguments:
//   vals = vector of values
//   all = set to true to return indices of all occurences of the maximum.  Default: false
function max_index(vals, all=false) =
        all ? search(max(vals),vals,0) : search(max(vals), vals)[0];

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


// Function: rand_int(min,max,N,seed)
// Usage:
//   rand_int(min,max,N,[seed]);
// Description:
//   Return a list of random integers in the range of min to max, inclusive.
// Arguments:
//   min = Minimum integer value to return.
//   max = Maximum integer value to return.
//   N = Number of random integers to return.
//   seed = Random number seed.
function rand_int(min,max,N,seed=undef) =
	assert(max >= min, "Max value cannot be smaller than min")
	let (rvect = is_def(seed) ? rands(min,max+1,N,seed) : rands(min,max+1,N))
	[for(entry = rvect) floor(entry)];


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
//   Returns the sum of all entries in the given list.
//   If passed an array of vectors, returns a vector of sums of each part.
// Arguments:
//   v = The list to get the sum of.
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


// Function: deltas()
// Description:
//   Returns a list with the deltas of adjacent entries in the given list.
//   Given [a,b,c,d], returns [b-a,c-b,d-c].
// Arguments:
//   v = The list to get the deltas of.
// Example:
//   deltas([2,5,9,17]);  // returns [3,4,8].
//   deltas([[1,2,3], [3,6,8], [4,8,11]]);  // returns [[2,4,5], [1,2,3]]
function deltas(v) = [for (p=pair(v)) p.y-p.x];


// Function: product()
// Description:
//   Returns the product of all entries in the given list.
//   If passed an array of vectors, returns a vector of products of each part.
//   If passed an array of matrices, returns a the resulting product matrix.
// Arguments:
//   v = The list to get the product of.
// Example:
//   product([2,3,4]);  // returns 24.
//   product([[1,2,3], [3,4,5], [5,6,7]]);  // returns [15, 48, 105]
function product(v, i=0, tot=undef) = i>=len(v)? tot : product(v, i+1, ((tot==undef)? v[i] : is_vector(v[i])? vmul(tot,v[i]) : tot*v[i]));


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


// Function: det2()
// Description:
//   Optimized function that returns the determinant for the given 2x2 square matrix.
// Arguments:
//   M = The 2x2 square matrix to get the determinant of.
// Example:
//   M = [ [6,-2], [1,8] ];
//   det = det3(M);  // Returns: 50
function det2(M) = M[0][0] * M[1][1] - M[0][1]*M[1][0];


// Function: det3()
// Description:
//   Optimized function that returns the determinant for the given 3x3 square matrix.
// Arguments:
//   M = The 3x3 square matrix to get the determinant of.
// Example:
//   M = [ [6,4,-2], [1,-2,8], [1,5,7] ];
//   det = det3(M);  // Returns: -334
function det3(M) =
	M[0][0] * (M[1][1]*M[2][2]-M[2][1]*M[1][2]) -
	M[1][0] * (M[0][1]*M[2][2]-M[2][1]*M[0][2]) +
	M[2][0] * (M[0][1]*M[1][2]-M[1][1]*M[0][2]);


// Function: determinant()
// Description:
//   Returns the determinant for the given square matrix.
// Arguments:
//   M = The NxN square matrix to get the determinant of.
// Example:
//   M = [ [6,4,-2,9], [1,-2,8,3], [1,5,7,6], [4,2,5,1] ];
//   det = determinant(M);  // Returns: 2267
function determinant(M) =
	assert(len(M)==len(M[0]))
	len(M)==1? M[0][0] :
	len(M)==2? det2(M) :
	len(M)==3? det3(M) :
	sum(
		[for (col=[0:1:len(M)-1])
			((col%2==0)? 1 : -1) *
			M[col][0] *
			determinant(
				[for (r=[1:1:len(M)-1])
					[for (c=[0:1:len(M)-1])
						if (c!=col) M[c][r]
					]
				]
			)
		]
	);


// Section: Comparisons and Logic


function _type_num(x) =
	is_undef(x)?  0 :
	is_bool(x)?   1 :
	is_num(x)?    2 :
	is_string(x)? 3 :
	is_list(x)?   4 : 5;


// Function: compare_vals()
// Usage:
//   compare_vals(a, b);
// Description:
//   Compares two values.  Lists are compared recursively.
//   If types are not the same, then undef < bool < num < str < list < range.
// Arguments:
//   a = First value to compare.
//   b = Second value to compare.
function compare_vals(a, b) =
	(a==b)? 0 :
	let(t1=_type_num(a), t2=_type_num(b)) (t1!=t2)? (t1-t2) :
	is_list(a)? compare_lists(a,b) :
	(a<b)? -1 : (a>b)? 1 : 0;


// Function: compare_lists()
// Usage:
//   compare_lists(a, b)
// Description:
//   Compare contents of two lists using `compare_vals()`.
//   Returns <0 if `a`<`b`.
//   Returns 0 if `a`==`b`.
//   Returns >0 if `a`>`b`.
// Arguments:
//   a = First list to compare.
//   b = Second list to compare.
function compare_lists(a, b) =
	a==b? 0 : let(
		cmps = [
			for(i=[0:1:min(len(a),len(b))-1]) let(
				cmp = compare_vals(a[i],b[i])
			) if(cmp!=0) cmp
		]
	) cmps==[]? (len(a)-len(b)) : cmps[0];


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
