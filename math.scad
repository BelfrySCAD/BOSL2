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
//   If `x` is a list, then every item in that list will be recursively quantized.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
// Example:
//   quant(12,4);    // Returns: 12
//   quant(13,4);    // Returns: 12
//   quant(13.1,4);  // Returns: 12
//   quant(14,4);    // Returns: 16
//   quant(14.1,4);  // Returns: 16
//   quant(15,4);    // Returns: 16
//   quant(16,4);    // Returns: 16
//   quant(9,3);     // Returns: 9
//   quant(10,3);    // Returns: 9
//   quant(10.4,3);  // Returns: 9
//   quant(10.5,3);  // Returns: 12
//   quant(11,3);    // Returns: 12
//   quant(12,3);    // Returns: 12
//   quant([12,13,13.1,14,14.1,15,16],4);  // Returns: [12,12,12,16,16,16,16]
//   quant([9,10,10.4,10.5,11,12],3);      // Returns: [9,9,9,12,12,12]
//   quant([[9,10,10.4],[10.5,11,12]],3);  // Returns: [[9,9,9],[12,12,12]]
function quant(x,y) =
	is_list(x)? [for (v=x) quant(v,y)] :
	floor(x/y+0.5)*y;


// Function: quantdn()
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding down to the previous multiple.
//   If `x` is a list, then every item in that list will be recursively quantized down.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
// Examples:
//   quantdn(12,4);    // Returns: 12
//   quantdn(13,4);    // Returns: 12
//   quantdn(13.1,4);  // Returns: 12
//   quantdn(14,4);    // Returns: 12
//   quantdn(14.1,4);  // Returns: 12
//   quantdn(15,4);    // Returns: 12
//   quantdn(16,4);    // Returns: 16
//   quantdn(9,3);     // Returns: 9
//   quantdn(10,3);    // Returns: 9
//   quantdn(10.4,3);  // Returns: 9
//   quantdn(10.5,3);  // Returns: 9
//   quantdn(11,3);    // Returns: 9
//   quantdn(12,3);    // Returns: 12
//   quantdn([12,13,13.1,14,14.1,15,16],4);  // Returns: [12,12,12,12,12,12,16]
//   quantdn([9,10,10.4,10.5,11,12],3);      // Returns: [9,9,9,9,9,12]
//   quantdn([[9,10,10.4],[10.5,11,12]],3);  // Returns: [[9,9,9],[9,9,12]]
function quantdn(x,y) =
	is_list(x)? [for (v=x) quantdn(v,y)] :
	floor(x/y)*y;


// Function: quantup()
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding up to the next multiple.
//   If `x` is a list, then every item in that list will be recursively quantized up.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
// Examples:
//   quantup(12,4);    // Returns: 12
//   quantup(13,4);    // Returns: 16
//   quantup(13.1,4);  // Returns: 16
//   quantup(14,4);    // Returns: 16
//   quantup(14.1,4);  // Returns: 16
//   quantup(15,4);    // Returns: 16
//   quantup(16,4);    // Returns: 16
//   quantup(9,3);     // Returns: 9
//   quantup(10,3);    // Returns: 12
//   quantup(10.4,3);  // Returns: 12
//   quantup(10.5,3);  // Returns: 12
//   quantup(11,3);    // Returns: 12
//   quantup(12,3);    // Returns: 12
//   quantup([12,13,13.1,14,14.1,15,16],4);  // Returns: [12,16,16,16,16,16,16]
//   quantup([9,10,10.4,10.5,11,12],3);      // Returns: [9,12,12,12,12,12]
//   quantup([[9,10,10.4],[10.5,11,12]],3);  // Returns: [[9,12,12],[12,12,12]]
function quantup(x,y) =
	is_list(x)? [for (v=x) quantup(v,y)] :
	ceil(x/y)*y;


// Function: constrain()
// Usage:
//   constrain(v, minval, maxval);
// Description:
//   Constrains value to a range of values between minval and maxval, inclusive.
// Arguments:
//   v = value to constrain.
//   minval = minimum value to return, if out of range.
//   maxval = maximum value to return, if out of range.
// Example:
//   constrain(-5, -1, 1);   // Returns: -1
//   constrain(5, -1, 1);    // Returns: 1
//   constrain(0.3, -1, 1);  // Returns: 0.3
//   constrain(9.1, 0, 9);   // Returns: 9
//   constrain(-0.1, 0, 9);  // Returns: 0
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
// Example:
//   approx(-0.3333333333,-1/3);  // Returns: true
//   approx(0.3333333333,1/3);    // Returns: true
//   approx(0.3333,1/3);          // Returns: false
//   approx(0.3333,1/3,eps=1e-3);  // Returns: true
//   approx(PI,3.1415926536);     // Returns: true
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
// Example:
//   min_index([5,3,9,6,2,7,8,2,1]); // Returns: 4
//   min_index([5,3,9,6,2,7,8,2,1],all=true); // Returns: [4,7]
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
// Example:
//   max_index([5,3,9,6,2,7,8,9,1]); // Returns: 2
//   max_index([5,3,9,6,2,7,8,9,1],all=true); // Returns: [2,7]
function max_index(vals, all=false) =
	all ? search(max(vals),vals,0) : search(max(vals), vals)[0];


// Function: posmod()
// Usage:
//   posmod(x,m)
// Description:
//   Returns the positive modulo `m` of `x`.  Value returned will be in the range 0 ... `m`-1.
// Arguments:
//   x = The value to constrain.
//   m = Modulo value.
// Example:
//   posmod(-700,360);  // Returns: 340
//   posmod(-270,360);  // Returns: 90
//   posmod(-120,360);  // Returns: 240
//   posmod(120,360);   // Returns: 120
//   posmod(270,360);   // Returns: 270
//   posmod(700,360);   // Returns: 340
//   posmod(3,2.5);     // Returns: 0.5
function posmod(x,m) = (x%m+m)%m;


// Function: modang(x)
// Usage:
//   ang = modang(x)
// Description:
//   Takes an angle in degrees and normalizes it to an equivalent angle value between -180 and 180.
// Example:
//   modang(-700,360);  // Returns: 20
//   modang(-270,360);  // Returns: 90
//   modang(-120,360);  // Returns: -120
//   modang(120,360);   // Returns: 120
//   modang(270,360);   // Returns: -90
//   modang(700,360);   // Returns: -20
function modang(x) =
	let(xx = posmod(x,360)) xx<180? xx : xx-360;


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
//   modrange(90,270,360, step=45);   // Returns: [90,135,180,225,270]
//   modrange(270,90,360, step=45);   // Returns: [270,315,0,45,90]
//   modrange(90,270,360, step=-45);  // Returns: [90,45,0,315,270]
//   modrange(270,90,360, step=-45);  // Returns: [270,225,180,135,90]
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


// Function: log2()
// Usage:
//   foo = log2(x);
// Description: Returns the logarith base 10 of the value given.
// Examples:
//   log2(0.125);  // Returns: -3
//   log2(16);     // Returns: 4
//   log2(256);    // Returns: 8
function log2(x) = ln(x)/ln(2);


// Function: rand_int()
// Usage:
//   rand_int(min,max,N,[seed]);
// Description:
//   Return a list of random integers in the range of min to max, inclusive.
// Arguments:
//   min = Minimum integer value to return.
//   max = Maximum integer value to return.
//   N = Number of random integers to return.
//   seed = If given, sets the random number seed.
// Example:
//   ints = rand_int(0,100,3);
//   int = rand_int(-10,10,1)[0];
function rand_int(min, max, N, seed=undef) =
	assert(max >= min, "Max value cannot be smaller than min")
	let (rvect = is_def(seed) ? rands(min,max+1,N,seed) : rands(min,max+1,N))
	[for(entry = rvect) floor(entry)];


// Function: gaussian_rands()
// Usage:
//   gaussian_rands(mean, stddev, [N], [seed])
// Description:
//   Returns a random number with a gaussian/normal distribution.
// Arguments:
//   mean = The average random number returned.
//   stddev = The standard deviation of the numbers to be returned.
//   N = Number of random numbers to return.  Default: 1
//   seed = If given, sets the random number seed.
function gaussian_rands(mean, stddev, N=1, seed=undef) =
	let(nums = is_undef(seed)? rands(0,1,N*2) : rands(0,1,N*2,seed))
	[for (i = list_range(N)) mean + stddev*sqrt(-2*ln(nums[i*2]))*cos(360*nums[i*2+1])];


// Function: log_rands()
// Usage:
//   log_rands(minval, maxval, factor, [N], [seed]);
// Description:
//   Returns a single random number, with a logarithmic distribution.
// Arguments:
//   minval = Minimum value to return.
//   maxval = Maximum value to return.  `minval` <= X < `maxval`.
//   factor = Log factor to use.  Values of X are returned `factor` times more often than X+1.
//   N = Number of random numbers to return.  Default: 1
//   seed = If given, sets the random number seed.
function log_rands(minval, maxval, factor, N=1, seed=undef) =
	assert(maxval >= minval, "maxval cannot be smaller than minval")
	let(
		minv = 1-1/pow(factor,minval),
		maxv = 1-1/pow(factor,maxval),
		nums = is_undef(seed)? rands(minv, maxv, N) : rands(minv, maxv, N, seed)
	) [for (num=nums) -ln(1-num)/ln(factor)];


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
//   u = The proportion from `a` to `b` to calculate.  Valid range is 0.0 to 1.0, inclusive.  If given as a list or range of values, returns a list of results.
function lerp(a,b,u) =
	is_num(u)? (1-u)*a + u*b :
	[for (v = u) lerp(a,b,v)];


// Function: hypot()
// Description: Calculate hypotenuse length of a 2D or 3D triangle.
// Arguments:
//   x = Length on the X axis.
//   y = Length on the Y axis.
//   z = Length on the Z axis.
function hypot(x,y,z=0) =
	norm([x,y,z]);


// Function: sinh()
// Description: Takes a value `x`, and returns the hyperbolic sine of it.
function sinh(x) =
	(exp(x)-exp(-x))/2;


// Function: cosh()
// Description: Takes a value `x`, and returns the hyperbolic cosine of it.
function cosh(x) =
	(exp(x)+exp(-x))/2;


// Function: tanh()
// Description: Takes a value `x`, and returns the hyperbolic tangent of it.
function tanh(x) =
	sinh(x)/cosh(x);


// Function: asinh()
// Description: Takes a value `x`, and returns the inverse hyperbolic sine of it.
function asinh(x) =
	ln(x+sqrt(x*x+1));


// Function: acosh()
// Description: Takes a value `x`, and returns the inverse hyperbolic cosine of it.
function acosh(x) =
	ln(x+sqrt(x*x-1));


// Function: atanh()
// Description: Takes a value `x`, and returns the inverse hyperbolic tangent of it.
function atanh(x) =
	ln((1+x)/(1-x))/2;


// Function: sum()
// Description:
//   Returns the sum of all entries in the given list.
//   If passed an array of vectors, returns a vector of sums of each part.
// Arguments:
//   v = The list to get the sum of.
// Example:
//   sum([1,2,3]);  // returns 6.
//   sum([[1,2,3], [3,4,5], [5,6,7]]);  // returns [9, 12, 15]
function sum(v, _i=0, _acc=undef) = _i>=len(v)? _acc : sum(v, _i+1, ((_acc==undef)? v[_i] : _acc+v[_i]));


// Function: cumsum()
// Description:
//   Returns a list where each item is the cumulative sum of all items up to and including the corresponding entry in the input list.
//   If passed an array of vectors, returns a list of cumulative vectors sums.
// Arguments:
//   v = The list to get the sum of.
// Example:
//   cumsum([1,1,1]);  // returns [1,2,3]
//   cumsum([2,2,2]);  // returns [2,4,6]
//   cumsum([1,2,3]);  // returns [1,3,6]
//   cumsum([[1,2,3], [3,4,5], [5,6,7]]);  // returns [[1,2,3], [4,6,8], [9,12,15]]
function cumsum(v,_i=0,_acc=[]) =
	_i==len(v) ? _acc :
	cumsum(
		v, _i+1,
		concat(
			_acc,
			[_i==0 ? v[_i] : select(_acc,-1)+v[_i]]
		)
	);


// Function: sum_of_squares()
// Description:
//   Returns the sum of the square of each element of a vector.
// Arguments:
//   v = The vector to get the sum of.
// Example:
//   sum_of_squares([1,2,3]);  // Returns: 14.
//   sum_of_squares([1,2,4]);  // Returns: 21
//   sum_of_squares([-3,-2,-1]);  // Returns: 14
function sum_of_squares(v, i=0, tot=0) = sum(vmul(v,v));


// Function: sum_of_sines()
// Usage:
//   sum_of_sines(a,sines)
// Description:
//   Gives the sum of a series of sines, at a given angle.
// Arguments:
//   a = Angle to get the value for.
//   sines = List of [amplitude, frequency, offset] items, where the frequency is the number of times the cycle repeats around the circle.
// Examples:
//   v = sum_of_sines(30, [[10,3,0], [5,5.5,60]]);
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
//   det = det2(M);  // Returns: 50
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

// If argument is a list return it.  Otherwise return a singleton list containing the argument. 
function _force_list(x) = is_list(x) ? x : [x];

// Function: gcd()
// Usage:
//   gcd(a,b)
// Description:
//   Computes the greatest common divisor of `a` and `b`.  
function gcd(a,b) =
   assert(is_integer(a) && is_integer(b),"Arguments to gcd must be integers")
   b==0 ? abs(a) : gcd(b,a % b);

// Computes lcm for two scalars
function _lcm(a,b) =
  let(
    parmok = is_integer(a) && is_integer(b),
    dummy=assert(parmok,"Invalid non-integer parameters to lcm")
          assert(a!=0 && b!=0, "Arguments to lcm must be nonzero")
  )
  abs(a*b) / gcd(a,b);

// Computes lcm for a list of values
function _lcmlist(a) =
    len(a)==1 ? a[0] : _lcmlist(concat(slice(a,0,len(a)-2),[lcm(a[len(a)-2],a[len(a)-1])]));

// Function: lcm()
// Usage:
//   lcm(a,b)
//   lcm(list)
// Description: Computes the least common multiple of the two arguments or a list of arguments.  Inputs should be
//   nonzero integers.  The output is always a positive integer.  It is an error to pass zero as an argument.  
function lcm(a,b=[]) =
  !is_list(a) && !is_list(b) ? _lcm(a,b) : 
  let(
    arglist = concat(_force_list(a),_force_list(b))
  )
  assert(len(arglist)>0,"invalid call to lcm with empty list(s)")
       _lcmlist(arglist);

// Function: is_integer()
// Usage:
//   is_integer(n)
// Description: returns true if the given value is an integer (it is a number and it rounds to itself).  
function is_integer(n) = is_num(n) && n == round(n);


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
