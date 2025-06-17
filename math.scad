//////////////////////////////////////////////////////////////////////
// LibFile: math.scad
//   Assorted math functions, including linear interpolation, list operations (sums, mean, products),
//   convolution, quantization, log2, hyperbolic trig functions, random numbers, derivatives,
//   polynomials, and root finding. 
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Math
// FileSummary: Math on lists, special functions, quantization, random numbers, calculus, root finding
//  
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

// Section: Math Constants

// Constant: PHI
// Synopsis: The golden ratio φ (phi).  Approximately 1.6180339887
// Topics: Constants, Math
// See Also: EPSILON, INF, NAN
// Description: The golden ratio φ (phi).  Approximately 1.6180339887
PHI = (1+sqrt(5))/2;

// Constant: EPSILON
// Synopsis: A tiny value to compare floating point values.  `1e-9`
// Topics: Constants, Math
// See Also: PHI, EPSILON, INF, NAN
// Description: A really small value useful in comparing floating point numbers.  ie: abs(a-b)<EPSILON  `1e-9`
EPSILON = 1e-9;

// Constant: INF
// Synopsis: The floating point value for Infinite.
// Topics: Constants, Math
// See Also: PHI, EPSILON, INF, NAN
// Description: The value `inf`, useful for comparisons.
INF = 1/0;

// Constant: NAN
// Synopsis: The floating point value for Not a Number.
// Topics: Constants, Math
// See Also: PHI, EPSILON, INF, NAN
// Description: The value `nan`, useful for comparisons.
NAN = acos(2);



// Section: Interpolation and Counting


// Function: count()
// Synopsis: Creates a list of incrementing numbers.
// Topics: Math, Indexing
// See Also: idx()
// Usage:
//   list = count(n, [s], [step], [reverse]);
// Description:
//   Creates a list of `n` numbers, starting at `s`, incrementing by `step` each time.
//   You can also pass a list for n and then the length of the input list is used.  
// Arguments:
//   n = The length of the list of numbers to create, or a list to match the length of.
//   s = The starting value of the list of numbers.
//   step = The amount to increment successive numbers in the list.
//   reverse = Reverse the list.  Default: false.
// Example:
//   nl1 = count(5);  // Returns: [0,1,2,3,4]
//   nl2 = count(5,3);  // Returns: [3,4,5,6,7]
//   nl3 = count(4,3,2);  // Returns: [3,5,7,9]
//   nl4 = count(5,reverse=true);    // Returns: [4,3,2,1,0]
//   nl5 = count(5,3,reverse=true);  // Returns: [7,6,5,4,3]
function count(n,s=0,step=1,reverse=false) = let(n=is_list(n) ? len(n) : n)
                                             reverse? [for (i=[n-1:-1:0]) s+i*step]
                                                    : [for (i=[0:1:n-1]) s+i*step];


// Function: lerp()
// Synopsis: Linearly interpolates between two values.
// Topics: Interpolation, Math
// See Also: v_lookup(), lerpn()
// Usage:
//   x = lerp(a, b, u);
//   l = lerp(a, b, LIST);
// Description:
//   Interpolate between two values or vectors.
//   * If `u` is given as a number, returns the single interpolated value.
//   * If `u` is 0.0, then the value of `a` is returned.
//   * If `u` is 1.0, then the value of `b` is returned.
//   * If `u` is a range, or list of numbers, returns a list of interpolated values.
//   .
//   It is valid to use a `u` value outside the range 0 to 1 to extrapolate
//   along the slope formed by `a` and `b`.
// Arguments:
//   a = First value or vector.
//   b = Second value or vector.
//   u = The proportion from `a` to `b` to calculate.  Standard range is 0.0 to 1.0, inclusive.  If given as a list or range of values, returns a list of results.
// Example:
//   x = lerp(0,20,0.3);  // Returns: 6
//   x = lerp(0,20,0.8);  // Returns: 16
//   x = lerp(0,20,-0.1); // Returns: -2
//   x = lerp(0,20,1.1);  // Returns: 22
//   p = lerp([0,0],[20,10],0.25);  // Returns [5,2.5]
//   l = lerp(0,20,[0.4,0.6]);  // Returns: [8,12]
//   l = lerp(0,20,[0.25:0.25:0.75]);  // Returns: [5,10,15]
// Example(2D):
//   p1 = [-50,-20];  p2 = [50,30];
//   stroke([p1,p2]);
//   pts = lerp(p1, p2, [0:1/8:1]);
//   // Points colored in ROYGBIV order.
//   rainbow(pts) translate($item) circle(d=3,$fn=8);
function lerp(a,b,u) =
    assert(same_shape(a,b), "\nBad or inconsistent inputs to lerp.")
    is_finite(u)? (1-u)*a + u*b :
    assert(is_finite(u) || is_vector(u) || valid_range(u), "\nInput u to lerp must be a number, vector, or valid range.")
    [for (v = u) (1-v)*a + v*b ];


// Function: lerpn()
// Synopsis: Returns exactly `n` values, linearly interpolated between `a` and `b`.
// Topics: Interpolation, Math
// See Also: v_lookup(), lerp()
// Usage:
//   x = lerpn(a, b, n);
//   x = lerpn(a, b, n, [endpoint]);
// Description:
//   Returns exactly `n` values, linearly interpolated between `a` and `b`.
//   If `endpoint` is true, then the last value will exactly equal `b`.
//   If `endpoint` is false, then the last value will be `a+(b-a)*(1-1/n)`.
// Arguments:
//   a = First value or vector.
//   b = Second value or vector.
//   n = The number of values to return.
//   endpoint = If true, the last value will be exactly `b`.  If false, the last value will be one step less.
// Example:
//   l = lerpn(-4,4,9);        // Returns: [-4,-3,-2,-1,0,1,2,3,4]
//   l = lerpn(-4,4,8,false);  // Returns: [-4,-3,-2,-1,0,1,2,3]
//   l = lerpn(0,1,6);         // Returns: [0, 0.2, 0.4, 0.6, 0.8, 1]
//   l = lerpn(0,1,5,false);   // Returns: [0, 0.2, 0.4, 0.6, 0.8]
function lerpn(a,b,n,endpoint=true) =
    assert(same_shape(a,b), "\nBad or inconsistent inputs to lerpn.")
    assert(is_int(n))
    assert(is_bool(endpoint))
    let( d = n - (endpoint? 1 : 0) )
    [for (i=[0:1:n-1]) let(u=i/d) (1-u)*a + u*b];

// Function: bilerp()
// Synopsis: Bi-linear interpolation between four values
// Topics: Interpolation, Math
// See Also: lerp()
// Usage:
//   x = bilerp(pts, x, y);
// Description:
//   Compute bilinear interpolation between four values using two
//   coordinates that are meant to lie in [0,1].  (If they are outside
//   this range, the function extrapolates values.)  The `pts`
//   argument is a list of the four values at the for corners, `[A,B,C,D]`.
//   These values are arranged on the corners as shown below.  The `x` and
//   `y` parameters give the fraction of the distance from the left and bottom
//   respectively.  
// Figure(Med,2D,NoScales): The layout of the points for the bilinear interpolation.
//  stroke(square(10),closed=true,width=.5);
//  move([-1,-1])
//  hide("thing")
//  tag_this("thing") square(10)
//    color("black")grid_copies(n=[2,2],spacing=14) text("ABCD"[$idx],size=3);
//  pt=[.6,.7]*10;
//  color("red")move(pt) circle(r=1/2,$fn=12);
//  color("blue"){
//    stroke([[-1.5,.3],[-1.5,pt.y]], width=1/2, color="blue",endcap2="arrow2");
//    stroke([[0,-1.5],[pt.x,-1.5]], width=1/2, color="blue",endcap2="arrow2");
//    fwd(4.5)right(3)text("x",size=2);
//    back(2)left(4)text("y",size=2);
//  }  
// Arguments:
//   points = Four point values at the corners
//   x = First proportional distance
//   y = Second proportional distance


function bilerp(points,x,y) =
     [1,y,x,x*y]*[[1, 0, 0, 0],[-1, 0, 1, 0],[-1,1,0,0],[1,-1,-1,1]]*points;



// Section: Miscellaneous Functions 

// Function: sqr()
// Synopsis: Returns the square of the given value.
// Topics: Math
// See Also: hypot(), log2()
// Usage:
//   x2 = sqr(x);
// Description:
//   If given a number, returns the square of that number,
//   If given a vector, returns the sum-of-squares/dot product of the vector elements.
//   If given a matrix, returns the matrix multiplication of the matrix with itself.
// Example:
//   sqr(3);     // Returns: 9
//   sqr(-4);    // Returns: 16
//   sqr([2,3,4]); // Returns: 29
//   sqr([[1,2],[3,4]]);  // Returns [[7,10],[15,22]]
function sqr(x) = 
    assert(is_finite(x) || is_vector(x) || is_matrix(x), "\nInput is not a number nor a list of numbers.")
    x*x;


// Function: log2()
// Synopsis: Returns the log base 2 of the given value.
// Topics: Math
// See Also: hypot(), sqr()
// Usage:
//   val = log2(x);
// Description:
//   Returns the logarithm base 2 of the value given.
// Example:
//   log2(0.125);  // Returns: -3
//   log2(16);     // Returns: 4
//   log2(256);    // Returns: 8
function log2(x) = 
    assert( is_finite(x), "\nInput is not a number.")
    ln(x)/ln(2);

// this may return NAN or INF; should it check x>0 ?

// Function: hypot()
// Synopsis: Returns the hypotenuse length of a 2D or 3D triangle.
// Topics: Math
// See Also: hypot(), sqr(), log2()
// Usage:
//   l = hypot(x, y, [z]);
// Description:
//   Calculate hypotenuse length of a 2D or 3D triangle.
// Arguments:
//   x = Length on the X axis.
//   y = Length on the Y axis.
//   z = Length on the Z axis.  Optional.
// Example:
//   l = hypot(3,4);  // Returns: 5
//   l = hypot(3,4,5);  // Returns: ~7.0710678119
function hypot(x,y,z=0) = 
    assert( is_vector([x,y,z]), "\nImproper number(s).")
    norm([x,y,z]);


// Function: factorial()
// Synopsis: Returns the factorial of the given integer.
// Topics: Math
// See Also: hypot(), sqr(), log2()
// Usage:
//   x = factorial(n, [d]);
// Description:
//   Returns the factorial of the given integer value, or n!/d! if d is given.  
// Arguments:
//   n = The integer number to get the factorial of.  (n!)
//   d = If given, the returned value is (n! / d!)
// Example:
//   x = factorial(4);  // Returns: 24
//   y = factorial(6);  // Returns: 720
//   z = factorial(9);  // Returns: 362880
function factorial(n,d=0) =
    assert(is_int(n) && is_int(d) && n>=0 && d>=0, "\nFactorial is defined only for non negative integers.")
    assert(d<=n, "\nd cannot be larger than n.")
    product([1,for (i=[n:-1:d+1]) i]);


// Function: binomial()
// Synopsis: Returns the binomial coefficients of the integer `n`.
// Topics: Math
// See Also: hypot(), sqr(), log2(), factorial()
// Usage:
//   x = binomial(n);
// Description:
//   Returns the binomial coefficients of the integer `n`.  
// Arguments:
//   n = The integer to get the binomial coefficients of
// Example:
//   x = binomial(3);  // Returns: [1,3,3,1]
//   y = binomial(4);  // Returns: [1,4,6,4,1]
//   z = binomial(6);  // Returns: [1,6,15,20,15,6,1]
function binomial(n) =
    assert( is_int(n) && n>0, "\nInput must be an integer greater than 0.")
    [for( c = 1, i = 0; 
        i<=n; 
         c = c*(n-i)/(i+1), i = i+1
        ) c ] ;


// Function: binomial_coefficient()
// Synopsis: Returns the `k`-th binomial coefficient of the integer `n`.
// Topics: Math
// See Also: hypot(), sqr(), log2(), factorial()
// Usage:
//   x = binomial_coefficient(n, k);
// Description:
//   Returns the `k`-th binomial coefficient of the integer `n`.
// Arguments:
//   n = The integer to get the binomial coefficient of
//   k = The binomial coefficient index
// Example:
//   x = binomial_coefficient(3,2);  // Returns: 3
//   y = binomial_coefficient(10,6); // Returns: 210
function binomial_coefficient(n,k) =
    assert( is_int(n) && is_int(k), "\nSome input is not a number.")
    k < 0 || k > n ? 0 :
    k ==0 || k ==n ? 1 :
    let( k = min(k, n-k),
         b = [for( c = 1, i = 0; 
                   i<=k; 
                   c = c*(n-i)/(i+1), i = i+1
                 ) c] )
    b[len(b)-1];


// Function: gcd()
// Synopsis: Returns the Greatest Common Divisor/Factor of two integers.
// Topics: Math
// See Also: hypot(), sqr(), log2(), factorial(), binomial(), gcd(), lcm()
// Usage:
//   x = gcd(a,b)
// Description:
//   Computes the Greatest Common Divisor/Factor of `a` and `b`.  
function gcd(a,b) =
    assert(is_int(a) && is_int(b),"\nArguments to gcd must be integers.")
    b==0 ? abs(a) : gcd(b,a % b);


// Computes lcm for two integers
function _lcm(a,b) =
    assert(is_int(a) && is_int(b), "\nInvalid non-integer parameters to lcm.")
    assert(a!=0 && b!=0, "\nArguments to lcm must be non-zero.")
    abs(a*b) / gcd(a,b);


// Computes lcm for a list of values
function _lcmlist(a) =
    len(a)==1 ? a[0] :
    _lcmlist(concat(lcm(a[0],a[1]),list_tail(a,2)));


// Function: lcm()
// Synopsis: Returns the Least Common Multiple of two or more integers.
// Topics: Math
// See Also: hypot(), sqr(), log2(), factorial(), binomial(), gcd(), lcm()
// Usage:
//   div = lcm(a, b);
//   divs = lcm(list);
// Description:
//   Computes the Least Common Multiple of the two arguments or a list of arguments.  Inputs should
//   be non-zero integers.  The output is always a positive integer.  It is an error to pass zero
//   as an argument.  
function lcm(a,b=[]) =
    !is_list(a) && !is_list(b) 
    ?   _lcm(a,b) 
    :   let( arglist = concat(force_list(a),force_list(b)) )
        assert(len(arglist)>0, "\nInvalid call to lcm with empty list(s).")
        _lcmlist(arglist);

// Function rational_approx()
// Usage:
//   pq = rational_approx(x, maxq);
// Description:
//   Finds the best rational approximation p/q to the number x so that q<=maxq.  Returns
//   the result as `[p,q]`.  If the input is zero, then returns `[0,1]`.  
// Example:
//   pq1 = rational_approx(PI,10);        // Returns: [22,7]
//   pq2 = rational_approx(PI,10000);     // Returns: [355, 113]
//   pq3 = rational_approx(221/323,500);  // Returns: [13,19]
//   pq4 = rational_approx(0,50);         // Returns: [0,1]
function rational_approx(x, maxq, cfrac=[], p, q) =
  let(
       next = floor(x),
       fracpart = x-next,
       cfrac = [each cfrac, next],
       pq = _cfrac_to_pq(cfrac)
  )
    approx(fracpart,0) ? pq 
  : pq[1]>maxq ? [p,q]
  : rational_approx(1/fracpart,maxq,cfrac, pq[0], pq[1]);


// Converts a continued fraction given as a list with leading integer term
// into a fraction in the form p / q, returning [p,q]. 
function _cfrac_to_pq(cfrac,p=0,q=1,ind) =
    is_undef(ind) ? _cfrac_to_pq(cfrac,p,q,len(cfrac)-1)
  : ind==0 ? [p+q*cfrac[0], q]
  : _cfrac_to_pq(cfrac, q, cfrac[ind]*q+p, ind-1);


// Section: Hyperbolic Trigonometry

// Function: sinh()
// Synopsis: Returns the hyperbolic sine of the given value.
// Topics: Math, Trigonometry
// See Also: sinh(), cosh(), tanh(), asinh(), acosh(), atanh()
// Usage:
//   a = sinh(x);
// Description: Takes a value `x`, and returns the hyperbolic sine of it.
function sinh(x) =
    assert(is_finite(x), "\nThe input must be a finite number.")
    (exp(x)-exp(-x))/2;

// Function: cosh()
// Synopsis: Returns the hyperbolic cosine of the given value.
// Topics: Math, Trigonometry
// See Also: sinh(), cosh(), tanh(), asinh(), acosh(), atanh()
// Usage:
//   a = cosh(x);
// Description: Takes a value `x`, and returns the hyperbolic cosine of it.
function cosh(x) =
    assert(is_finite(x), "\nThe input must be a finite number.")
    (exp(x)+exp(-x))/2;


// Function: tanh()
// Synopsis: Returns the hyperbolic tangent of the given value.
// Topics: Math, Trigonometry
// See Also: sinh(), cosh(), tanh(), asinh(), acosh(), atanh()
// Usage:
//   a = tanh(x);
// Description: Takes a value `x`, and returns the hyperbolic tangent of it.

function tanh(x) =
    assert(is_finite(x), "\nThe input must be a finite number.")
    let (e = exp(2*x) + 1)
    e == INF ? 1 : (e-2)/e;

// Function: asinh()
// Synopsis: Returns the hyperbolic arc-sine of the given value.
// Topics: Math, Trigonometry
// See Also: sinh(), cosh(), tanh(), asinh(), acosh(), atanh()
// Usage:
//   a = asinh(x);
// Description: Takes a value `x`, and returns the inverse hyperbolic sine of it.
function asinh(x) =
    assert(is_finite(x), "\nThe input must be a finite number.")
    ln(x+sqrt(x*x+1));


// Function: acosh()
// Synopsis: Returns the hyperbolic arc-cosine of the given value.
// Topics: Math, Trigonometry
// See Also: sinh(), cosh(), tanh(), asinh(), acosh(), atanh()
// Usage:
//   a = acosh(x);
// Description: Takes a value `x`, and returns the inverse hyperbolic cosine of it.
function acosh(x) =
    assert(is_finite(x), "\nThe input must be a finite number.")
    ln(x+sqrt(x*x-1));


// Function: atanh()
// Synopsis: Returns the hyperbolic arc-tangent of the given value.
// Topics: Math, Trigonometry
// See Also: sinh(), cosh(), tanh(), asinh(), acosh(), atanh()
// Usage:
//   a = atanh(x);
// Description: Takes a value `x`, and returns the inverse hyperbolic tangent of it.
function atanh(x) =
    assert(is_finite(x), "\nThe input must be a finite number.")
    ln((1+x)/(1-x))/2;


// Section: Quantization

// Function: quant()
// Synopsis: Returns `x` quantized to the nearest integer multiple of `y`.
// Topics: Math, Quantization
// See Also: quant(), quantdn(), quantup()
// Usage:
//   num = quant(x, y);
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding to the nearest multiple.
//   The value of `y` does NOT have to be an integer.  If `x` is a list, then every item
//   in that list is recursively quantized.
// Arguments:
//   x = The value or list to quantize.
//   y = Positive quantum to quantize to
// Example:
//   a = quant(12,4);    // Returns: 12
//   b = quant(13,4);    // Returns: 12
//   c = quant(13.1,4);  // Returns: 12
//   d = quant(14,4);    // Returns: 16
//   e = quant(14.1,4);  // Returns: 16
//   f = quant(15,4);    // Returns: 16
//   g = quant(16,4);    // Returns: 16
//   h = quant(9,3);     // Returns: 9
//   i = quant(10,3);    // Returns: 9
//   j = quant(10.4,3);  // Returns: 9
//   k = quant(10.5,3);  // Returns: 12
//   l = quant(11,3);    // Returns: 12
//   m = quant(12,3);    // Returns: 12
//   n = quant(11,2.5);  // Returns: 10
//   o = quant(12,2.5);  // Returns: 12.5
//   p = quant([12,13,13.1,14,14.1,15,16],4);  // Returns: [12,12,12,16,16,16,16]
//   q = quant([9,10,10.4,10.5,11,12],3);      // Returns: [9,9,9,12,12,12]
//   r = quant([[9,10,10.4],[10.5,11,12]],3);  // Returns: [[9,9,9],[12,12,12]]
function quant(x,y) =
    assert( is_finite(y) && y>0, "\nThe quantum `y` must be a positive value.")
    is_num(x) ? round(x/y)*y 
              : _roundall(x/y)*y;

function _roundall(data) =
    [for(x=data) is_list(x) ? _roundall(x) : round(x)];


// Function: quantdn()
// Synopsis: Returns `x` quantized down to an integer multiple of `y`.
// Topics: Math, Quantization
// See Also: quant(), quantdn(), quantup()
// Usage:
//   num = quantdn(x, y);
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding down to the previous multiple.
//   The value of `y` does NOT have to be an integer.  If `x` is a list, then every item in that
//   list is recursively quantized down.
// Arguments:
//   x = The value or list to quantize.
//   y = Postive quantum to quantize to. 
// Example:
//   a = quantdn(12,4);    // Returns: 12
//   b = quantdn(13,4);    // Returns: 12
//   c = quantdn(13.1,4);  // Returns: 12
//   d = quantdn(14,4);    // Returns: 12
//   e = quantdn(14.1,4);  // Returns: 12
//   f = quantdn(15,4);    // Returns: 12
//   g = quantdn(16,4);    // Returns: 16
//   h = quantdn(9,3);     // Returns: 9
//   i = quantdn(10,3);    // Returns: 9
//   j = quantdn(10.4,3);  // Returns: 9
//   k = quantdn(10.5,3);  // Returns: 9
//   l = quantdn(11,3);    // Returns: 9
//   m = quantdn(12,3);    // Returns: 12
//   n = quantdn(11,2.5);  // Returns: 10
//   o = quantdn(12,2.5);  // Returns: 10
//   p = quantdn([12,13,13.1,14,14.1,15,16],4);  // Returns: [12,12,12,12,12,12,16]
//   q = quantdn([9,10,10.4,10.5,11,12],3);      // Returns: [9,9,9,9,9,12]
//   r = quantdn([[9,10,10.4],[10.5,11,12]],3);  // Returns: [[9,9,9],[9,9,12]]
function quantdn(x,y) =
    assert( is_finite(y) && y>0, "\nThe quantum `y` must be a positive value.")
    is_num(x) ? floor(x/y)*y 
              : _floorall(x/y)*y;

function _floorall(data) =
    [for(x=data) is_list(x) ? _floorall(x) : floor(x)];


// Function: quantup()
// Synopsis: Returns `x` quantized uo to an integer multiple of `y`.
// Topics: Math, Quantization
// See Also: quant(), quantdn(), quantup()
// Usage:
//   num = quantup(x, y);
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding up to the next multiple.
//   The value of `y` does NOT have to be an integer.  If `x` is a list, then every item in
//   that list is recursively quantized up.
// Arguments:
//   x = The value or list to quantize.
//   y = Positive quantum to quantize to.
// Example:
//   a = quantup(12,4);    // Returns: 12
//   b = quantup(13,4);    // Returns: 16
//   c = quantup(13.1,4);  // Returns: 16
//   d = quantup(14,4);    // Returns: 16
//   e = quantup(14.1,4);  // Returns: 16
//   f = quantup(15,4);    // Returns: 16
//   g = quantup(16,4);    // Returns: 16
//   h = quantup(9,3);     // Returns: 9
//   i = quantup(10,3);    // Returns: 12
//   j = quantup(10.4,3);  // Returns: 12
//   k = quantup(10.5,3);  // Returns: 12
//   l = quantup(11,3);    // Returns: 12
//   m = quantup(12,3);    // Returns: 12
//   n = quantdn(11,2.5);  // Returns: 12.5
//   o = quantdn(12,2.5);  // Returns: 12.5
//   p = quantup([12,13,13.1,14,14.1,15,16],4);  // Returns: [12,16,16,16,16,16,16]
//   q = quantup([9,10,10.4,10.5,11,12],3);      // Returns: [9,12,12,12,12,12]
//   r = quantup([[9,10,10.4],[10.5,11,12]],3);  // Returns: [[9,12,12],[12,12,12]]
function quantup(x,y) =
    assert( is_finite(y) && y>0, "\nThe quantum `y` must be a positive value.")
    is_num(x) ? ceil(x/y)*y 
              : _ceilall(x/y)*y;

function _ceilall(data) =
    [for(x=data) is_list(x) ? _ceilall(x) : ceil(x)];


// Section: Constraints and Modulos

// Function: constrain()
// Synopsis: Limit (clamp) a number or array of numbers to a specified range of values.
// Topics: Math
// See Also: posmod(), modang()
// Usage:
//   vals = constrain(v, minval, maxval);
// Description:
//   Returns the value(s) in `v` limited to the range defined by `minval` and `maxval`.
//   This operation is also known as "clamping" in other computer languages.
// Arguments:
//   m = Value(s) to constrain. Can be a numerical value, a 1D vector, a 2D rectangular matrix, or a list of different-length vectors.
//   minval = Minimum value to return. Set to `-INF` to unrestrict the minimum.
//   maxval = Maximum value to return. Set to `INF` to unrestrict the maximum.
// Example:
//   a = constrain(-5, -1, 1);   // Returns: -1
//   b = constrain(5, -1, 1);    // Returns: 1
//   c = constrain(0.3, -1, 1);  // Returns: 0.3
//   d = constrain(9.1, 0, 9);   // Returns: 9
//   e = constrain([1,2,3,4,5,6,7,8,9], 3, 7);          // Returns: [3,3,3,4,5,6,7,7,7]
//   f = constrain([[1,2,3], [4,5,6], [7,8,9]], 3, 7);  // Returns: [[3,3,3], [4,5,6], [7,7,7]]
//   g = constrain([[1,2,3,4], [5,6,7], [8,9]], 3, 7);  // Returns: [[3,3,3,4], [5,6,7], [7,7]]
function constrain(v, minval, maxval) =
    is_num(v) ? max(minval, min(v, maxval))
    : is_vector(v) ? [for(f=v) max(minval, min(f, maxval))]
    : is_matrix(v) ? let( // for a matrix, this should be more efficient than indexing
        mflat = flatten(v),
        clamped = [ for(f=mflat) max(minval, min(f, maxval)) ] 
    ) list_to_matrix(clamped, len(v[0]), 0)
    : is_list(v) ? [ for(vec=v) [ for(f=vec) max(minval, min(f, maxval)) ] ]
    : assert(false, "\nIn constrain(), v must be a number, 1D vector, rectangular matrix, or list of vectors.");


// Function: posmod()
// Synopsis: Returns the positive modulo of a value.
// Topics: Math
// See Also: constrain(), posmod(), modang()
// Usage:
//   mod = posmod(x, m)
// Description:
//   Returns the positive modulo `m` of `x`. The value returned satisfies `0 <= mod < m`.  
// Arguments:
//   x = The value to constrain.
//   m = Modulo value.
// Example:
//   a = posmod(-700,360);  // Returns: 340
//   b = posmod(-270,360);  // Returns: 90
//   c = posmod(-120,360);  // Returns: 240
//   d = posmod(120,360);   // Returns: 120
//   e = posmod(270,360);   // Returns: 270
//   f = posmod(700,360);   // Returns: 340
//   g = posmod(3,2.5);     // Returns: 0.5
function posmod(x,m) = 
    assert( is_finite(x) && is_finite(m) && !approx(m,0) , "\nInput must be finite numbers. The divisor cannot be zero.")
    (x%m+m)%m;


// Function: modang()
// Synopsis: Returns an angle normalized to between -180º and 180º.
// Topics: Math
// See Also: constrain(), posmod(), modang()
// Usage:
//   ang = modang(x);
// Description:
//   Takes an angle in degrees and normalizes it to an equivalent angle value between -180 and 180.
// Example:
//   a1 = modang(-700);  // Returns: 20
//   a2 = modang(-270);  // Returns: 90
//   a3 = modang(-120);  // Returns: -120
//   a4 = modang(120);   // Returns: 120
//   a5 = modang(270);   // Returns: -90
//   a6 = modang(700);   // Returns: -20
function modang(x) =
    assert( is_finite(x), "\nInput must be a finite number.")
    let(xx = posmod(x,360)) xx<180? xx : xx-360;


// Function: mean_angle()
// Synopsis: Returns the mean angle of two angles
// Topics: Math
// See Also: modang()
// Usage:
//   half_ang = mean_angle(angle1,angle2);
// Description:
//   Takes two angles (degrees) in any range and finds the angle halfway between
//   the given angles, where halfway is interpreted using the shorter direction.
//   In the case where the angles are exactly 180 degrees apart,
//   it returns `angle1+90`.  The returned angle is always in the interval [0,360).  
// Arguments:
//   angle1 = first angle
//   angle2 = second angle
function mean_angle(angle1,angle2) =
    assert(is_vector([angle1,angle2]), "\nInputs must be finite numbers.")
    let(
        ang1 = posmod(angle1,360),
        ang2 = posmod(angle2,360)
    )
    approx(abs(ang1-ang2),180) ? posmod(angle1+90,360)
  : abs(ang1-ang2)<=180 ? (ang1+ang2)/2
  : posmod((ang1+ang2-360)/2,360);


// Function: fit_to_range()
// Synopsis: Scale the values in an array to span a range.
// Topics: Math, Bounds, Scaling
// See Also: fit_to_box()
// Usage:
//   a = fit_to_range(M, minval, maxval);
// Description:
//   Given a vector or list of vectors, scale the values so that they span the full range from `minval` to
//   `maxval`. If `minval>maxval`, then the output is a rescaled mirror image of the input.
// Arguments:
//   M = vector or list of vectors to scale. A list of vectors needn't be a rectangular matrix; the vectors can have different lengths.
//   minval = Minimum value of the rescaled data range.
//   maxval = Maximum value of the rescaled data range.
// Example:
//   a =  [0.0066, 0.194, 0.598, 0.194, 0.0066];
//   v = fit_to_range(a,5,10);
//   // Returns: [5, 6.584, 10, 6.584, 5]
//   
//   b = [ [20,20,0], [40,80,20], [60,40,20] ];
//   m = fit_to_range(b,-10,10);
//   // Returns:  [[-5,-5,-10], [0,10,-5], [5,0,-5]]
//   
//   c = [2,3,4,5,6];
//   inv = fit_to_range(c, 20, 8); // inverted range!
//   // Returns:  [20, 17, 14, 11, 8]
// Example(3D): A texture tile that spans the range [-1,1] is rescaled to span [0,1], resulting in the edges of the texture (which were at z=0) to be raised due to raising the minimu from -1 to 0.
//   tex = [
//       [0,0,0, 0, 0, 0,0,0,0],
//       [0,1,1, 1, 1, 1,1,1,0],
//       [0,1,0, 0, 0, 0,0,1,0],
//       [0,1,0,-1,-1,-1,0,1,0],
//       [0,1,0,-1, 0,-1,0,1,0],
//       [0,1,0,-1,-1,-1,0,1,0],
//       [0,1,0, 0, 0, 0,0,1,0],
//       [0,1,1, 1, 1, 1,1,1,0],
//       [0,0,0, 0, 0, 0,0,0,0]
//   ];
//   left(5) textured_tile(tex,
//       [9,9,2],tex_reps=1, anchor=BOTTOM);
//   right(5) textured_tile(fit_to_range(tex,0,1),
//       [9,9,2],tex_reps=1, anchor=BOTTOM);

function fit_to_range(M, minval, maxval) =
    let(
        is_vec = is_vector(M),
        dum = assert(is_vec || (is_list(M) && is_vector(M[0])), "\nParameter M must be a vector or list of vectors."),
        rowlen = len(is_vec ? M : M[0]),
        v = is_vec ? M : flatten(M),
        a = min(v),
        b = max(v)
    ) a==b ? M
    : is_vec ? add_scalar(add_scalar(M,-a) * ((maxval-minval)/(b-a)), minval)
    : [ for(row=M)
        add_scalar(add_scalar(row, -a) * ((maxval-minval)/(b-a)), + minval)
    ];


// Section: Operations on Lists (Sums, Mean, Products)

// Function: sum()
// Synopsis: Returns the sum of a list of values.
// Topics: Math
// See Also: mean(), median(), product(), cumsum()
// Usage:
//   x = sum(v, [dflt]);
// Description:
//   Returns the sum of all entries in the given consistent list.
//   If passed an array of vectors, returns the sum the vectors.
//   If passed an array of matrices, returns the sum of the matrices.
//   If passed an empty list, the value of `dflt` is returned.
// Arguments:
//   v = The list to get the sum of.
//   dflt = The default value to return if `v` is an empty list.  Default: 0
// Example:
//   sum([1,2,3]);  // returns 6.
//   sum([[1,2,3], [3,4,5], [5,6,7]]);  // returns [9, 12, 15]
function sum(v, dflt=0) =
    v==[]? dflt :
    assert(is_consistent(v), "\nInput to sum is non-numeric or inconsistent.")
    is_finite(v[0]) || is_vector(v[0]) ? [for(i=v) 1]*v :
    _sum(v,v[0]*0);

function _sum(v,_total,_i=0) = _i>=len(v) ? _total : _sum(v,_total+v[_i], _i+1);




// Function: mean()
// Synopsis: Returns the mean value of a list of values.
// Topics: Math, Statistics
// See Also: sum(), mean(), median(), product()
// Usage:
//   x = mean(v);
// Description:
//   Returns the arithmetic mean/average of all entries in the given array.
//   If passed a list of vectors, returns a vector of the mean of each part.
// Arguments:
//   v = The list of values to get the mean of.
// Example:
//   mean([2,3,4]);  // returns 3.
//   mean([[1,2,3], [3,4,5], [5,6,7]]);  // returns [3, 4, 5]
function mean(v) = 
    assert(is_list(v) && len(v)>0, "\nInvalid list.")
    sum(v)/len(v);



// Function: median()
// Synopsis: Returns the median value of a list of values.
// Topics: Math, Statistics
// See Also: sum(), mean(), median(), product()
// Usage:
//   middle = median(v)
// Description:
//   Returns the median of the given vector.  
function median(v) =
    assert(is_vector(v), "\nInput to median must be a vector.")
    len(v)%2 ? max( list_smallest(v, ceil(len(v)/2)) ) :
    let( lowest = list_smallest(v, len(v)/2 + 1),
         max  = max(lowest),
         imax = search(max,lowest,1),
         max2 = max([for(i=idx(lowest)) if(i!=imax[0]) lowest[i] ])
    )
    (max+max2)/2;


// Function: deltas()
// Synopsis: Returns the deltas between a list of values.
// Topics: Math, Statistics
// See Also: sum(), mean(), median(), product()
// Usage:
//   delts = deltas(v,[wrap]);
// Description:
//   Returns a list with the deltas of adjacent entries in the given list, optionally wrapping back to the front.
//   The list should be a consistent list of numeric components (numbers, vectors, matrix, etc).
//   Given [a,b,c,d], returns [b-a,c-b,d-c].
// Arguments:
//   v = The list to get the deltas of.
//   wrap = If true, wrap back to the start from the end.  ie: return the difference between the last and first items as the last delta.  Default: false
// Example:
//   deltas([2,5,9,17]);  // returns [3,4,8].
//   deltas([[1,2,3], [3,6,8], [4,8,11]]);  // returns [[2,4,5], [1,2,3]]
function deltas(v, wrap=false) = 
    assert( is_consistent(v) && len(v)>1 , "\nInconsistent list or with length<=1.")
    [for (p=pair(v,wrap)) p[1]-p[0]] ;


// Function: cumsum()
// Synopsis: Returns the running cumulative sum of a list of values.
// Topics: Math, Statistics
// See Also: sum(), mean(), median(), product()
// Usage:
//   sums = cumsum(v);
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
function cumsum(v) =
    v==[] ? [] :
    assert(is_consistent(v), "\nThe input is not consistent." )
    [for (a = v[0],
          i = 1
            ;
          i <= len(v)
            ;
          a = i<len(v) ? a+v[i] : a,
          i = i+1)
        a];
  
// Function: product()
// Synopsis: Returns the multiplicative product of a list of values.
// Topics: Math, Statistics
// See Also: sum(), mean(), median(), product(), cumsum()
// Usage:
//   x = product(v);
// Description:
//   Returns the product of all entries in the given list.
//   If passed a list of vectors of same length, returns a vector of the component-wise products of the input.
//   If passed a list of square matrices, returns the resulting product matrix.  Matrices are multiplied in the order they appear in the list.
// Arguments:
//   v = The list to get the product of.
// Example:
//   product([2,3,4]);  // returns 24.
//   product([[1,2,3], [3,4,5], [5,6,7]]);  // returns [15, 48, 105]
function product(list,right=true) =
    list==[] ? [] :
    is_matrix(list) ?
                [for (a = list[0], 
                      i = 1
                        ;
                      i <= len(list)
                        ;
                      a = i<len(list) ? v_mul(a,list[i]) : 0,
                      i = i+1)
                    if (i==len(list)) a][0]
   :  
    assert(is_vector(list) || (is_matrix(list[0],square=true) && is_consistent(list)),
           "\nInput must be a vector, a list of vectors, or a list of matrices.")
    [for (a = list[0],
          i = 1
            ;
          i <= len(list)
            ;
          a = i<len(list) ? a*list[i] : 0,
          i = i+1)
       if (i==len(list)) a][0];


// Function: cumprod()
// Synopsis: Returns the running cumulative product of a list of values.
// Topics: Math, Statistics
// See Also: sum(), mean(), median(), product(), cumsum()
// Usage:
//   prod_list = cumprod(list, [right]);
// Description:
//   Returns a list where each item is the cumulative product of all items up to and including the corresponding entry in the input list.
//   If passed an array of vectors, returns a list of elementwise vector products.  If passed a list of square matrices by default returns matrix
//   products multiplying on the left, so a list `[A,B,C]` produces the output `[A,BA,CBA]`.  If you set `right=true` then it returns
//   the product of multiplying on the right, so a list `[A,B,C]` produces the output `[A,AB,ABC]` in that case.
// Arguments:
//   list = The list to get the cumulative product of.
//   right = if true multiply matrices on the right
// Example:
//   cumprod([1,3,5]);  // returns [1,3,15]
//   cumprod([2,2,2]);  // returns [2,4,8]
//   cumprod([[1,2,3], [3,4,5], [5,6,7]]));  // returns [[1, 2, 3], [3, 8, 15], [15, 48, 105]]

function cumprod(list,right=false) =
    list==[] ? [] :
    is_matrix(list) ?
                [for (a = list[0], 
                      i = 1
                        ;
                      i <= len(list)
                        ;
                      a = i<len(list) ? v_mul(a,list[i]) : 0,
                      i = i+1)
                    a]
   :  
    assert(is_vector(list) || (is_matrix(list[0],square=true) && is_consistent(list)),
           "\nInput must be a listector, a list of listectors, or a list of matrices.")
    [for (a = list[0],
          i = 1
            ;
          i <= len(list)
            ;
          a = i<len(list) ? (right ? a*list[i] : list[i]*a) : 0,
          i = i+1)
        a];


// Function: convolve()
// Synopsis: Returns the convolution of `p` and `q`.
// Topics: Math, Statistics
// See Also: sum(), mean(), median(), product(), cumsum()
// Usage:
//   x = convolve(p,q);
// Description:
//   Given two vectors, or one vector and a path or
//   two paths of the same dimension, finds the convolution of them.
//   If both parameter are vectors, returns the vector convolution.
//   If one parameter is a vector and the other a path,
//   convolves using products by scalars and returns a path. 
//   If both parameters are paths, convolve using scalar products
//   and returns a vector.
//   The returned vector or path has length len(p)+len(q)-1.
// Arguments:
//   p = The first vector or path.
//   q = The second vector or path.
// Example:
//   a = convolve([1,1],[1,2,1]); // Returns: [1,3,3,1]
//   b = convolve([1,2,3],[1,2,1])); // Returns: [1,4,8,8,3]
//   c = convolve([[1,1],[2,2],[3,1]],[1,2,1])); // Returns: [[1,1],[4,4],[8,6],[8,4],[3,1]]
//   d = convolve([[1,1],[2,2],[3,1]],[[1,2],[2,1]])); // Returns:  [3,9,11,7]
function convolve(p,q) =
    p==[] || q==[] ? [] :
    assert( (is_vector(p) || is_matrix(p))
            && ( is_vector(q) || (is_matrix(q) && ( !is_vector(p[0]) || (len(p[0])==len(q[0])) ) ) ) ,
            "\nThe inputs should be vectors or paths all of the same dimension.")
    let( n = len(p),
         m = len(q))
    [for(i=[0:n+m-2], k1 = max(0,i-n+1), k2 = min(i,m-1) )
       sum([for(j=[k1:k2]) p[i-j]*q[j] ]) 
    ];



// Function: sum_of_sines()
// Synopsis: Returns the sum of one or more sine waves at a given angle.
// Topics: Math, Statistics
// See Also: sum(), mean(), median(), product(), cumsum()
// Usage:
//   sum_of_sines(a,sines)
// Description:
//   Given a list of sine waves, returns the sum of the sines at the given angle.
//   Each sine wave is given as an `[AMPLITUDE, FREQUENCY, PHASE_ANGLE]` triplet.
//   - `AMPLITUDE` is the height of the sine wave above (and below) `0`.
//   - `FREQUENCY` is the number of times the sine wave repeats in 360º.
//   - `PHASE_ANGLE` is the offset in degrees of the sine wave.
// Arguments:
//   a = Angle to get the value for.
//   sines = List of [amplitude, frequency, phase_angle] items, where the frequency is the number of times the cycle repeats around the circle.
// Example:
//   v = sum_of_sines(30, [[10,3,0], [5,5.5,60]]);
function sum_of_sines(a, sines) =
    assert( is_finite(a) && is_matrix(sines,undef,3), "Invalid input.")
    sum([ for (s = sines) 
            let(
              ss=point3d(s),
              v=ss[0]*sin(a*ss[1]+ss[2])
            ) v
        ]);



// Section: Random Number Generation

// Function: rand_int()
// Synopsis: Returns a random integer.
// Topics: Random
// See Also: rand_int(), random_points(), gaussian_rands(), random_polygon(), spherical_random_points(), exponential_rands()
// Usage:
//   rand_int(minval, maxval, n, [seed]);
// Description:
//   Return a list of random integers in the range of minval to maxval, inclusive.
// Arguments:
//   minval = Minimum integer value to return.
//   maxval = Maximum integer value to return.
//   N = Number of random integers to return.
//   seed = If given, sets the random number seed.
// Example:
//   ints = rand_int(0,100,3);
//   int = rand_int(-10,10,1)[0];
function rand_int(minval, maxval, n, seed=undef) =
    assert( is_finite(minval+maxval+n) && (is_undef(seed) || is_finite(seed) ), "\nInput must be finite numbers.")
    assert(maxval >= minval, "\nMax value cannot be smaller than minval.")
    let (rvect = is_def(seed) ? rands(minval,maxval+1,n,seed) : rands(minval,maxval+1,n))
    [for(entry = rvect) floor(entry)];


// Function: random_points()
// Synopsis: Returns a list of random points.
// Topics: Random, Points
// See Also: rand_int(), random_points(), random_polygon(), spherical_random_points()
// Usage:
//    points = random_points(n, dim, [scale], [seed]);
// Description:
//    Generate `n` uniform random points of dimension `dim` with data ranging from -scale to +scale.  
//    The `scale` may be a number, in which case the random data lies in a cube,
//    or a vector with dimension `dim`, in which case each dimension has its own scale.  
// Arguments:
//    n = number of points to generate. Default: 1
//    dim = dimension of the points. Default: 2
//    scale = the scale of the point coordinates. Default: 1
//    seed = an optional seed for the random generation.
function random_points(n, dim, scale=1, seed) =
    assert( is_int(n) && n>=0, "\nThe number of points should be a non-negative integer.")
    assert( is_int(dim) && dim>=1, "\nThe point dimensions should be an integer greater than 1.")
    assert( is_finite(scale) || is_vector(scale,dim), "\nThe scale should be a number or a vector with length equal to d.")
    let( 
        rnds =   is_undef(seed) 
                ? rands(-1,1,n*dim)
                : rands(-1,1,n*dim, seed) )
    is_num(scale) 
    ? scale*[for(i=[0:1:n-1]) [for(j=[0:dim-1]) rnds[i*dim+j] ] ]
    : [for(i=[0:1:n-1]) [for(j=[0:dim-1]) scale[j]*rnds[i*dim+j] ] ];


// Function: gaussian_rands()
// Synopsis: Returns a list of random numbers with a gaussian distribution.
// Topics: Random, Statistics
// See Also: rand_int(), random_points(), gaussian_rands(), random_polygon(), spherical_random_points(), exponential_rands()
// Usage:
//   arr = gaussian_rands([n],[mean], [cov], [seed]);
// Description:
//   Returns a random number or vector with a Gaussian/normal distribution.
// Arguments:
//   n = the number of points to return.  Default: 1
//   mean = The average of the random value (a number or vector).  Default: 0
//   cov = covariance matrix of the random numbers, or variance in the 1D case. Default: 1
//   seed = If given, sets the random number seed.
function gaussian_rands(n=1, mean=0, cov=1, seed=undef) =
    assert(is_num(mean) || is_vector(mean))
    let(
        dim = is_num(mean) ? 1 : len(mean)
    )
    assert((dim==1 && is_num(cov)) || is_matrix(cov,dim,dim),"\nmean and covariance matrix not compatible.")
    assert(is_undef(seed) || is_finite(seed))
    let(
         nums = is_undef(seed)? rands(0,1,dim*n*2) : rands(0,1,dim*n*2,seed),
         rdata = [for (i = count(dim*n,0,2)) sqrt(-2*ln(nums[i]))*cos(360*nums[i+1])]
    )
    dim==1 ? add_scalar(sqrt(cov)*rdata,mean) :
    assert(is_matrix_symmetric(cov),"\nSupplied covariance matrix is not symmetric.")
    let(
        L = cholesky(cov)
    )
    assert(is_def(L), "\nSupplied covariance matrix is not positive definite.")
    move(mean,list_to_matrix(rdata,dim)*transpose(L));


// Function: exponential_rands()
// Synopsis: Returns a list of random numbers with an exponential distribution.
// Topics: Random, Statistics
// See Also: rand_int(), random_points(), gaussian_rands(), random_polygon(), spherical_random_points()
// Usage:
//   arr = exponential_rands([n], [lambda], [seed])
// Description:
//   Returns random numbers with an exponential distribution with parameter lambda, and hence mean 1/lambda.  
// Arguments:
//   n = number of points to return.  Default: 1
//   lambda = distribution parameter.  The mean will be 1/lambda.  Default: 1
function exponential_rands(n=1, lambda=1, seed) =
    assert( is_int(n) && n>=1, "The number of points should be an integer greater than zero.")
    assert( is_num(lambda) && lambda>0, "The lambda parameter must be a positive number.")
    let(
         unif = is_def(seed) ? rands(0,1,n,seed=seed) : rands(0,1,n)
    )
    -(1/lambda) * [for(x=unif) x==1 ? 708.3964185322641 : ln(1-x)];  // Use ln(min_float) when x is 1


// Function: spherical_random_points()
// Synopsis: Returns a list of random points on the surface of a sphere.
// Topics: Random, Points
// See Also: rand_int(), random_points(), gaussian_rands(), random_polygon(), spherical_random_points()
// Usage:
//    points = spherical_random_points([n], [radius], [seed]);
// Description:
//    Generate `n` 3D uniformly distributed random points lying on a sphere centered at the origin with radius equal to `radius`.
// Arguments:
//    n = number of points to generate. Default: 1
//    radius = the sphere radius. Default: 1
//    seed = an optional seed for the random generation.

// See https://mathworld.wolfram.com/SpherePointPicking.html
function spherical_random_points(n=1, radius=1, seed) =
    assert( is_int(n) && n>=1, "The number of points should be an integer greater than zero.")
    assert( is_num(radius) && radius>0, "The radius should be a non-negative number.")
    let( theta = is_undef(seed) 
                ? rands(0,360,n)
                : rands(0,360,n, seed),
         cosphi = rands(-1,1,n))
    [for(i=[0:1:n-1]) let(
                          sin_phi=sqrt(1-cosphi[i]*cosphi[i])
                      )
                      radius*[sin_phi*cos(theta[i]),sin_phi*sin(theta[i]), cosphi[i]]];



// Function: random_polygon()
// Synopsis: Returns the CCW path of a simple random polygon.
// Topics: Random, Polygon
// See Also: random_points(), spherical_random_points()
// Usage:
//    points = random_polygon([n], [size], [seed]);
// Description:
//    Generate the `n` vertices of a random counter-clockwise simple 2d polygon 
//    inside a circle centered at the origin with radius `size`.
// Arguments:
//    n = number of vertices of the polygon. Default: 3
//    size = the radius of a circle centered at the origin containing the polygon. Default: 1
//    seed = an optional seed for the random generation.
function random_polygon(n=3,size=1, seed) =
    assert( is_int(n) && n>2, "Improper number of polygon vertices.")
    assert( is_num(size) && size>0, "Improper size.")
    let( 
        seed = is_undef(seed) ? rands(0,1,1)[0] : seed,
        cumm = cumsum(rands(0.1,10,n+1,seed)),
        angs = 360*cumm/cumm[n-1],
        rads = rands(.01,size,n,seed+cumm[0])
      )
    [for(i=count(n)) rads[i]*[cos(angs[i]), sin(angs[i])] ];



// Section: Calculus

// Function: deriv()
// Synopsis: Returns the first derivative estimate of a list of data.
// Topics: Math, Calculus
// See Also: deriv(), deriv2(), deriv3()
// Usage:
//   x = deriv(data, [h], [closed])
// Description:
//   Computes a numerical derivative estimate of the data, which may be scalar or vector valued.
//   The `h` parameter gives the step size of your sampling so the derivative can be scaled correctly. 
//   If the `closed` parameter is true the data is assumed to be defined on a loop with data[0] adjacent to
//   data[len(data)-1].  This function uses a symetric derivative approximation
//   for internal points, f'(t) = (f(t+h)-f(t-h))/2h.  For the endpoints (when closed=false) the algorithm
//   uses a two point method if sufficient points are available: f'(t) = (3*(f(t+h)-f(t)) - (f(t+2*h)-f(t+h)))/2h.
//   .
//   If `h` is a vector then it is assumed to be nonuniform, with h[i] giving the sampling distance
//   between data[i+1] and data[i], and the data values are linearly resampled at each corner
//   to produce a uniform spacing for the derivative estimate.  At the endpoints a single point method
//   is used: f'(t) = (f(t+h)-f(t))/h.  
// Arguments:
//   data = the list of the elements to compute the derivative of.
//   h = the parametric sampling of the data.
//   closed = boolean to indicate if the data set should be wrapped around from the end to the start.
function deriv(data, h=1, closed=false) =
    assert( is_consistent(data) , "Input list is not consistent or not numerical.") 
    assert( len(data)>=2, "Input `data` should have at least 2 elements.") 
    assert( is_finite(h) || is_vector(h), "The sampling `h` must be a number or a list of numbers." )
    assert( is_num(h) || len(h) == len(data)-(closed?0:1),
            str("Vector valued `h` must have length ",len(data)-(closed?0:1)))
    is_vector(h) ? _deriv_nonuniform(data, h, closed=closed) :
    let( L = len(data) )
    closed
    ? [
        for(i=[0:1:L-1])
        (data[(i+1)%L]-data[(L+i-1)%L])/2/h
      ]
    : let(
        first = L<3 ? data[1]-data[0] : 
                3*(data[1]-data[0]) - (data[2]-data[1]),
        last = L<3 ? data[L-1]-data[L-2]:
               (data[L-3]-data[L-2])-3*(data[L-2]-data[L-1])
         ) 
      [
        first/2/h,
        for(i=[1:1:L-2]) (data[i+1]-data[i-1])/2/h,
        last/2/h
      ];


function _dnu_calc(f1,fc,f2,h1,h2) =
    let(
        f1 = h2<h1 ? lerp(fc,f1,h2/h1) : f1 , 
        f2 = h1<h2 ? lerp(fc,f2,h1/h2) : f2
       )
    (f2-f1) / 2 / min(h1,h2);


function _deriv_nonuniform(data, h, closed) =
    let( L = len(data) )
    closed
    ? [for(i=[0:1:L-1])
          _dnu_calc(data[(L+i-1)%L], data[i], data[(i+1)%L], select(h,i-1), h[i]) ]
    : [
        (data[1]-data[0])/h[0],
        for(i=[1:1:L-2]) _dnu_calc(data[i-1],data[i],data[i+1], h[i-1],h[i]),
        (data[L-1]-data[L-2])/h[L-2]                            
      ];


// Function: deriv2()
// Synopsis: Returns the second derivative estimate of a list of data.
// Topics: Math, Calculus
// See Also: deriv(), deriv2(), deriv3()
// Usage:
//   x = deriv2(data, [h], [closed])
// Description:
//   Computes a numerical estimate of the second derivative of the data, which may be scalar or vector valued.
//   The `h` parameter gives the step size of your sampling so the derivative can be scaled correctly. 
//   If the `closed` parameter is true the data is assumed to be defined on a loop with data[0] adjacent to
//   data[len(data)-1].  For internal points this function uses the approximation 
//   f''(t) = (f(t-h)-2*f(t)+f(t+h))/h^2.  For the endpoints (when closed=false),
//   when sufficient points are available, the method is either the four point expression
//   f''(t) = (2*f(t) - 5*f(t+h) + 4*f(t+2*h) - f(t+3*h))/h^2 or 
//   f''(t) = (35*f(t) - 104*f(t+h) + 114*f(t+2*h) - 56*f(t+3*h) + 11*f(t+4*h)) / 12h^2
//   if five points are available.
// Arguments:
//   data = the list of the elements to compute the derivative of.
//   h = the constant parametric sampling of the data.
//   closed = boolean to indicate if the data set should be wrapped around from the end to the start.
function deriv2(data, h=1, closed=false) =
    assert( is_consistent(data) , "Input list is not consistent or not numerical.") 
    assert( is_finite(h), "The sampling `h` must be a number." )
    let( L = len(data) )
    assert( L>=3, "Input list has less than 3 elements.") 
    closed
    ? [
        for(i=[0:1:L-1])
        (data[(i+1)%L]-2*data[i]+data[(L+i-1)%L])/h/h
      ]
    :
    let(
        first = 
            L==3? data[0] - 2*data[1] + data[2] :
            L==4? 2*data[0] - 5*data[1] + 4*data[2] - data[3] :
            (35*data[0] - 104*data[1] + 114*data[2] - 56*data[3] + 11*data[4])/12, 
        last = 
            L==3? data[L-1] - 2*data[L-2] + data[L-3] :
            L==4? -2*data[L-1] + 5*data[L-2] - 4*data[L-3] + data[L-4] :
            (35*data[L-1] - 104*data[L-2] + 114*data[L-3] - 56*data[L-4] + 11*data[L-5])/12
    ) [
        first/h/h,
        for(i=[1:1:L-2]) (data[i+1]-2*data[i]+data[i-1])/h/h,
        last/h/h
    ];


// Function: deriv3()
// Synopsis: Returns the third derivative estimate of a list of data.
// Topics: Math, Calculus
// See Also: deriv(), deriv2(), deriv3()
// Usage:
//   x = deriv3(data, [h], [closed])
// Description:
//   Computes a numerical third derivative estimate of the data, which may be scalar or vector valued.
//   The `h` parameter gives the step size of your sampling so the derivative can be scaled correctly. 
//   If the `closed` parameter is true the data is assumed to be defined on a loop with data[0] adjacent to
//   data[len(data)-1].  This function uses a five point derivative estimate, so the input data must include 
//   at least five points:
//   f'''(t) = (-f(t-2*h)+2*f(t-h)-2*f(t+h)+f(t+2*h)) / 2h^3.  At the first and second points from the end
//   the estimates are f'''(t) = (-5*f(t)+18*f(t+h)-24*f(t+2*h)+14*f(t+3*h)-3*f(t+4*h)) / 2h^3 and
//   f'''(t) = (-3*f(t-h)+10*f(t)-12*f(t+h)+6*f(t+2*h)-f(t+3*h)) / 2h^3.
// Arguments:
//   data = the list of the elements to compute the derivative of.
//   h = the constant parametric sampling of the data.
//   closed = boolean to indicate if the data set should be wrapped around from the end to the start.
function deriv3(data, h=1, closed=false) =
    assert( is_consistent(data) , "Input list is not consistent or not numerical.") 
    assert( len(data)>=5, "Input list has less than 5 elements.") 
    assert( is_finite(h), "The sampling `h` must be a number." )
    let(
        L = len(data),
        h3 = h*h*h
    )
    closed? [
        for(i=[0:1:L-1])
        (-data[(L+i-2)%L]+2*data[(L+i-1)%L]-2*data[(i+1)%L]+data[(i+2)%L])/2/h3
    ] :
    let(
        first=(-5*data[0]+18*data[1]-24*data[2]+14*data[3]-3*data[4])/2,
        second=(-3*data[0]+10*data[1]-12*data[2]+6*data[3]-data[4])/2,
        last=(5*data[L-1]-18*data[L-2]+24*data[L-3]-14*data[L-4]+3*data[L-5])/2,
        prelast=(3*data[L-1]-10*data[L-2]+12*data[L-3]-6*data[L-4]+data[L-5])/2
    ) [
        first/h3,
        second/h3,
        for(i=[2:1:L-3]) (-data[i-2]+2*data[i-1]-2*data[i+1]+data[i+2])/2/h3,
        prelast/h3,
        last/h3
    ];


// Section: Complex Numbers


// Function: complex()
// Synopsis: Replaces scalars in a list or matrix with complex number 2-vectors.
// Topics: Math, Complex Numbers
// See Also: c_mul(), c_div(), c_conj(), c_real(), c_imag(), c_ident(), c_norm()
// Usage:
//   z = complex(list)
// Description:
//   Converts a real valued number, vector or matrix into its complex analog
//   by replacing all entries with a 2-vector that has zero imaginary part.
function complex(list) =
   is_num(list) ? [list,0] :
   [for(entry=list) is_num(entry) ? [entry,0] : complex(entry)];


// Function: c_mul()
// Synopsis: Multiplies two complex numbers.
// Topics: Math, Complex Numbers
// See Also: complex(), c_mul(), c_div(), c_conj(), c_real(), c_imag(), c_ident(), c_norm()
// Usage:
//   c = c_mul(z1,z2)
// Description:
//   Multiplies two complex numbers, vectors or matrices, where complex numbers
//   or entries are represented as vectors: [REAL, IMAGINARY].  All
//   entries in both arguments must be complex.  
// Arguments:
//   z1 = First complex number, vector or matrix
//   z2 = Second complex number, vector or matrix
function c_mul(z1,z2) =
    is_matrix([z1,z2],2,2) ? _c_mul(z1,z2) :
    _combine_complex(_c_mul(_split_complex(z1), _split_complex(z2)));


function _split_complex(data) =
    is_vector(data,2) ? data
    : is_num(data[0][0]) ? [data*[1,0], data*[0,1]]
    : [
      [for(vec=data) vec * [1,0]],
      [for(vec=data) vec * [0,1]]
     ];


function _combine_complex(data) =
    is_vector(data,2) ? data
    : is_num(data[0][0]) ? [for(i=[0:len(data[0])-1]) [data[0][i],data[1][i]]]
    : [for(i=[0:1:len(data[0])-1])
          [for(j=[0:1:len(data[0][0])-1])  
              [data[0][i][j], data[1][i][j]]]];


function _c_mul(z1,z2) = 
    [ z1.x*z2.x - z1.y*z2.y, z1.x*z2.y + z1.y*z2.x ];


// Function: c_div()
// Synopsis: Divides two complex numbers.
// Topics: Math, Complex Numbers
// See Also: complex(), c_mul(), c_div(), c_conj(), c_real(), c_imag(), c_ident(), c_norm()
// Usage:
//   x = c_div(z1,z2)
// Description:
//   Divides two complex numbers represented by 2D vectors.  
//   Returns a complex number as a 2D vector [REAL, IMAGINARY].
// Arguments:
//   z1 = First complex number, given as a 2D vector [REAL, IMAGINARY]
//   z2 = Second complex number, given as a 2D vector [REAL, IMAGINARY]
function c_div(z1,z2) = 
    assert( is_vector(z1,2) && is_vector(z2), "Complex numbers should be represented by 2D vectors." )
    assert( !approx(z2,0), "The divisor `z2` cannot be zero." ) 
    let(den = z2.x*z2.x + z2.y*z2.y)
    [(z1.x*z2.x + z1.y*z2.y)/den, (z1.y*z2.x - z1.x*z2.y)/den];


// Function: c_conj()
// Synopsis: Returns the complex conjugate of the input.
// Topics: Math, Complex Numbers
// See Also: complex(), c_mul(), c_div(), c_conj(), c_real(), c_imag(), c_ident(), c_norm()
// Usage:
//   w = c_conj(z)
// Description:
//   Computes the complex conjugate of the input, which can be a complex number,
//   complex vector or complex matrix.  
function c_conj(z) =
   is_vector(z,2) ? [z.x,-z.y] :
   [for(entry=z) c_conj(entry)];


// Function: c_real()
// Synopsis: Returns the real part of a complex number, vector or matrix..
// Topics: Math, Complex Numbers
// See Also: complex(), c_mul(), c_div(), c_conj(), c_real(), c_imag(), c_ident(), c_norm()
// Usage:
//   x = c_real(z)
// Description:
//   Returns real part of a complex number, vector or matrix.
function c_real(z) = 
     is_vector(z,2) ? z.x
   : is_num(z[0][0]) ? z*[1,0]
   : [for(vec=z) vec * [1,0]];


// Function: c_imag()
// Synopsis: Returns the imaginary part of a complex number, vector or matrix..
// Topics: Math, Complex Numbers
// See Also: complex(), c_mul(), c_div(), c_conj(), c_real(), c_imag(), c_ident(), c_norm()
// Usage:
//   x = c_imag(z)
// Description:
//   Returns imaginary part of a complex number, vector or matrix.
function c_imag(z) = 
     is_vector(z,2) ? z.y
   : is_num(z[0][0]) ? z*[0,1]
   : [for(vec=z) vec * [0,1]];


// Function: c_ident()
// Synopsis: Returns an n by n complex identity matrix.
// Topics: Math, Complex Numbers
// See Also: complex(), c_mul(), c_div(), c_conj(), c_real(), c_imag(), c_ident(), c_norm()
// Usage:
//   I = c_ident(n)
// Description:
//   Produce an n by n complex identity matrix
function c_ident(n) = [for (i = [0:1:n-1]) [for (j = [0:1:n-1]) (i==j)?[1,0]:[0,0]]];


// Function: c_norm()
// Synopsis: Returns the norm of a complex number or vector.
// Topics: Math, Complex Numbers
// See Also: complex(), c_mul(), c_div(), c_conj(), c_real(), c_imag(), c_ident(), c_norm()
// Usage:
//   n = c_norm(z)
// Description:
//   Compute the norm of a complex number or vector. 
function c_norm(z) = norm_fro(z);


// Section: Polynomials

// Function: quadratic_roots()
// Synopsis: Computes roots for the quadratic equation.
// Topics: Math, Geometry, Complex Numbers
// See Also: quadratic_roots(), polynomial(), poly_mult(), poly_div(), poly_add()
// Usage:
//    roots = quadratic_roots(a, b, c, [real])
// Description:
//    Computes roots of the quadratic equation a*x^2+b*x+c==0, where the
//    coefficients are real numbers.  If real is true, then returns only the
//    real roots.  Otherwise returns a pair of complex values.  This method
//    may be more reliable than the general root finder at distinguishing
//    real roots from complex roots.  
//    Algorithm from: https://people.csail.mit.edu/bkph/articles/Quadratics.pdf
function quadratic_roots(a,b,c,real=false) =
  real ? [for(root = quadratic_roots(a,b,c,real=false)) if (root.y==0) root.x]
  :
  is_undef(b) && is_undef(c) && is_vector(a,3) ? quadratic_roots(a[0],a[1],a[2]) :
  assert(is_num(a) && is_num(b) && is_num(c))
  assert(a!=0 || b!=0 || c!=0, "Quadratic must have a nonzero coefficient")
  a==0 && b==0 ? [] :     // No solutions
  a==0 ? [[-c/b,0]] : 
  let(
      descrim = b*b-4*a*c,
      sqrt_des = sqrt(abs(descrim))
  )
  descrim < 0 ?             // Complex case
     [[-b, sqrt_des],
      [-b, -sqrt_des]]/2/a :
  b<0 ?                     // b positive
     [[2*c/(-b+sqrt_des),0],
      [(-b+sqrt_des)/a/2,0]]
      :                     // b negative
     [[(-b-sqrt_des)/2/a, 0],
      [2*c/(-b-sqrt_des),0]];


// Function: polynomial() 
// Synopsis: Evaluate a polynomial at a real or complex value.
// Topics: Math, Complex Numbers
// See Also: quadratic_roots(), polynomial(), poly_mult(), poly_div(), poly_add(), poly_roots()
// Usage:
//   x = polynomial(p, z)
// Description:
//   Evaluates specified real polynomial, p, at the complex or real input value, z.
//   The polynomial is specified as p=[a_n, a_{n-1},...,a_1,a_0]
//   where a_n is the z^n coefficient.  Polynomial coefficients are real.
//   The result is a number if `z` is a number and a complex number otherwise.
function polynomial(p,z,k,total) =
  is_undef(k)
  ? assert( is_vector(p) , "Input polynomial coefficients must be a vector." )
    assert( is_finite(z) || is_vector(z,2), "The value of `z` must be a real or a complex number." )
    polynomial( _poly_trim(p), z, 0, is_num(z) ? 0 : [0,0])
  : k==len(p) ? total
  : polynomial(p,z,k+1, is_num(z) ? total*z+p[k] : c_mul(total,z)+[p[k],0]);


// Function: poly_mult()
// Synopsis: Compute product of two polynomials, returning a polynomial.
// Topics: Math
// See Also: quadratic_roots(), polynomial(), poly_mult(), poly_div(), poly_add(), poly_roots()
// Usage:
//   x = polymult(p,q)
//   x = polymult([p1,p2,p3,...])
// Description:
//   Given a list of polynomials represented as real algebraic coefficient lists, with the highest degree coefficient first, 
//   computes the coefficient list of the product polynomial.  
function poly_mult(p,q) = 
  is_undef(q) ?
    len(p)==2 
        ? poly_mult(p[0],p[1]) 
    : poly_mult(p[0], poly_mult(list_tail(p)))
  :
  assert( is_vector(p) && is_vector(q),"Invalid arguments to poly_mult")
    p*p==0 || q*q==0
    ? [0]
    : _poly_trim(convolve(p,q));

    
// Function: poly_div()
// Synopsis: Returns the polynomial quotient and remainder results of dividing two polynomials.
// Topics: Math
// See Also: quadratic_roots(), polynomial(), poly_mult(), poly_div(), poly_add(), poly_roots()
// Usage:
//    [quotient,remainder] = poly_div(n,d)
// Description:
//    Computes division of the numerator polynomial by the denominator polynomial and returns
//    a list of two polynomials, [quotient, remainder].  If the division has no remainder then
//    the zero polynomial [0] is returned for the remainder.  Similarly if the quotient is zero
//    the returned quotient is [0].  
function poly_div(n,d) =
    assert( is_vector(n) && is_vector(d) , "Invalid polynomials." )
    let( d = _poly_trim(d), 
         n = _poly_trim(n) )
    assert( d!=[0] , "Denominator cannot be a zero polynomial." )
    n==[0]
    ? [[0],[0]]
    : _poly_div(n,d,q=[]);

function _poly_div(n,d,q) =
    len(n)<len(d) ? [q,_poly_trim(n)] : 
    let(
      t = n[0] / d[0], 
      newq = concat(q,[t]),
      newn = [for(i=[1:1:len(n)-1]) i<len(d) ? n[i] - t*d[i] : n[i]]
    )  
    _poly_div(newn,d,newq);


/// Internal Function: _poly_trim()
/// Usage:
///    _poly_trim(p, [eps])
/// Description:
///    Removes leading zero terms of a polynomial.  By default zeros must be exact,
///    or give epsilon for approximate zeros. Returns [0] for a zero polynomial.
function _poly_trim(p,eps=0) =
    let( nz = [for(i=[0:1:len(p)-1]) if ( !approx(p[i],0,eps)) i])
    len(nz)==0 ? [0] : list_tail(p,nz[0]);


// Function: poly_add()
// Synopsis: Returns the polynomial sum of adding two polynomials.
// Topics: Math
// See Also: quadratic_roots(), polynomial(), poly_mult(), poly_div(), poly_add(), poly_roots()
// Usage:
//    sum = poly_add(p,q)
// Description:
//    Computes the sum of two polynomials.  
function poly_add(p,q) = 
    assert( is_vector(p) && is_vector(q), "Invalid input polynomial(s)." )
    let(  plen = len(p),
          qlen = len(q),
          long = plen>qlen ? p : q,
          short = plen>qlen ? q : p
       )
     _poly_trim(long + concat(repeat(0,len(long)-len(short)),short));


// Function: poly_roots()
// Synopsis: Returns all complex valued roots of the given real polynomial.
// Topics: Math, Complex Numbers
// See Also: quadratic_roots(), polynomial(), poly_mult(), poly_div(), poly_add(), poly_roots()
// Usage:
//   roots = poly_roots(p, [tol]);
// Description:
//   Returns all complex roots of the specified real polynomial p.
//   The polynomial is specified as p=[a_n, a_{n-1},...,a_1,a_0]
//   where a_n is the z^n coefficient.  The tol parameter gives
//   the stopping tolerance for the iteration.  The polynomial
//   must have at least one non-zero coefficient.  Convergence is poor
//   if the polynomial has any repeated roots other than zero.  
// Arguments:
//   p = polynomial coefficients with higest power coefficient first
//   tol = tolerance for iteration.  Default: 1e-14

// Uses the Aberth method https://en.wikipedia.org/wiki/Aberth_method
//
// Dario Bini. "Numerical computation of polynomial zeros by means of Aberth's Method", Numerical Algorithms, Feb 1996.
// https://www.researchgate.net/publication/225654837_Numerical_computation_of_polynomial_zeros_by_means_of_Aberth's_method
function poly_roots(p,tol=1e-14,error_bound=false) =
    assert( is_vector(p), "Invalid polynomial." )
    let( p = _poly_trim(p,eps=0) )
    assert( p!=[0], "Input polynomial cannot be zero." )
    p[len(p)-1] == 0 ?                                       // Strip trailing zero coefficients
        let( solutions = poly_roots(list_head(p),tol=tol, error_bound=error_bound))
        (error_bound ? [ [[0,0], each solutions[0]], [0, each solutions[1]]]
                    : [[0,0], each solutions]) :
    len(p)==1 ? (error_bound ? [[],[]] : []) :               // Nonzero constant case has no solutions
    len(p)==2 ? let( solution = [[-p[1]/p[0],0]])            // Linear case needs special handling
                (error_bound ? [solution,[0]] : solution)
    : 
    let(
        n = len(p)-1,   // polynomial degree
        pderiv = [for(i=[0:n-1]) p[i]*(n-i)],
           
        s = [for(i=[0:1:n]) abs(p[i])*(4*(n-i)+1)],  // Error bound polynomial from Bini

        // Using method from: http://www.kurims.kyoto-u.ac.jp/~kyodo/kokyuroku/contents/pdf/0915-24.pdf
        beta = -p[1]/p[0]/n,
        r = 1+pow(abs(polynomial(p,beta)/p[0]),1/n),
        init = [for(i=[0:1:n-1])                // Initial guess for roots       
                 let(angle = 360*i/n+270/n/PI)
                 [beta,0]+r*[cos(angle),sin(angle)]
               ],
        roots = _poly_roots(p,pderiv,s,init,tol=tol),
        error = error_bound ? [for(xi=roots) n * (norm(polynomial(p,xi))+tol*polynomial(s,norm(xi))) /
                                  abs(norm(polynomial(pderiv,xi))-tol*polynomial(s,norm(xi)))] : 0
      )
      error_bound ? [roots, error] : roots;

// Internal function
// p = polynomial
// pderiv = derivative polynomial of p
// z = current guess for the roots
// tol = root tolerance
// i=iteration counter
function _poly_roots(p, pderiv, s, z, tol, i=0) =
    assert(i<45, str("Polyroot exceeded iteration limit.  Current solution:", z))
    let(
        n = len(z),
        svals = [for(zk=z) tol*polynomial(s,norm(zk))],
        p_of_z = [for(zk=z) polynomial(p,zk)],
        done = [for(k=[0:n-1]) norm(p_of_z[k])<=svals[k]],
        newton = [for(k=[0:n-1]) c_div(p_of_z[k], polynomial(pderiv,z[k]))],
        zdiff = [for(k=[0:n-1]) sum([for(j=[0:n-1]) if (j!=k) c_div([1,0], z[k]-z[j])])],
        w = [for(k=[0:n-1]) done[k] ? [0,0] : c_div( newton[k],
                                                     [1,0] - c_mul(newton[k], zdiff[k]))]
    )
    all(done) ? z : _poly_roots(p,pderiv,s,z-w,tol,i+1);


// Function: real_roots()
// Synopsis: Returns all real roots of the given real polynomial.
// Topics: Math, Complex Numbers
// See Also: quadratic_roots(), polynomial(), poly_mult(), poly_div(), poly_add(), poly_roots()
// Usage:
//   roots = real_roots(p, [eps], [tol])
// Description:
//   Returns the real roots of the specified real polynomial p.
//   The polynomial is specified as p=[a_n, a_{n-1},...,a_1,a_0]
//   where a_n is the x^n coefficient.  This function works by
//   computing the complex roots and returning those roots where
//   the imaginary part is closed to zero.  By default it uses a computed
//   error bound from the polynomial solver to decide whether imaginary
//   parts are zero.  You can specify eps, in which case the test is
//   z.y/(1+norm(z)) < eps.  Because
//   of poor convergence and higher error for repeated roots, such roots may
//   be missed by the algorithm because error can make their imaginary parts
//   large enough to appear non-zero.  
// Arguments:
//   p = polynomial to solve as coefficient list, highest power term first
//   eps = used to determine whether imaginary parts of roots are zero
//   tol = tolerance for the complex polynomial root finder

function real_roots(p,eps=undef,tol=1e-14) =
    assert( is_vector(p), "Invalid polynomial." )
    let( p = _poly_trim(p,eps=0) )
    assert( p!=[0], "Input polynomial cannot be zero." )
    let( 
       roots_err = poly_roots(p,error_bound=true),
       roots = roots_err[0],
       err = roots_err[1]
    )
    is_def(eps) 
    ? [for(z=roots) if (abs(z.y)/(1+norm(z))<eps) z.x]
    : [for(i=idx(roots)) if (abs(roots[i].y)<=err[i]) roots[i].x];


// Section: Operations on Functions

// Function: root_find()
// Synopsis: Finds a root of the given continuous function.
// Topics: Math
// See Also: quadratic_roots(), polynomial(), poly_mult(), poly_div(), poly_add(), poly_roots()
// Usage:
//    x = root_find(f, x0, x1, [tol])
// Description:
//    Find a root of the continuous function f where the sign of f(x0) is different
//    from the sign of f(x1).  The function f is a function literal accepting one
//    argument.  You must have a version of OpenSCAD that supports function literals
//    (2021.01 or newer).  The tolerance (tol) specifies the accuracy of the solution:
//    abs(f(x)) < tol * yrange, where yrange is the range of observed function values.
//    This function can find only those roots that *cross* the x axis: it cannot find the
//    the root of x^2.
// Arguments:
//    f = function literal for a scalar-valued single variable function
//    x0 = endpoint of interval to search for root
//    x1 = second endpoint of interval to search for root
//    tol = tolerance for solution.  Default: 1e-15
// Example(2D): Solve x*sin(x)=4
//    f = function (x) x*sin(x)-4;
//    root=root_find(f, 0,25); // root = 15.2284
//        // Graphical verification
//    stroke([for(x=[0:25]) [x,f(x)]],width=.2);
//    color("red")move([root,f(root)])
//        circle(r=.25,$fn=16);


//   The algorithm is based on Brent's method and is a combination of
//   bisection and inverse quadratic approximation, where bisection occurs
//   at every step, with refinement using inverse quadratic approximation
//   only when that approximation gives a good result.  The detail
//   of how to decide when to use the quadratic came from an article
//   by Crenshaw on "The World's Best Root Finder".
//   https://www.embedded.com/worlds-best-root-finder/
function root_find(f,x0,x1,tol=1e-15) =
   let(
        y0 = f(x0),
        y1 = f(x1),
        yrange = y0<y1 ? [y0,y1] : [y1,y0]
   )
   // Check endpoints
   y0==0 || _rfcheck(x0, y0,yrange,tol) ? x0 :
   y1==0 || _rfcheck(x1, y1,yrange,tol) ? x1 :
   assert(y0*y1<0, "Sign of function must be different at the interval endpoints")
   _rootfind(f,[x0,x1],[y0,y1],yrange,tol);

function _rfcheck(x,y,range,tol) =
   assert(is_finite(y), str("Function not finite at ",x))
   abs(y) < tol*(range[1]-range[0]);

// xpts and ypts are arrays whose first two entries contain the
// interval bracketing the root.  Extra entries are ignored.
// yrange is the total observed range of y values (used for the
// tolerance test).  
function _rootfind(f, xpts, ypts, yrange, tol, i=0) =
    assert(i<100, "root_find did not converge to a solution")
    let(
         xmid = (xpts[0]+xpts[1])/2,
         ymid = f(xmid),
         yrange = [min(ymid, yrange[0]), max(ymid, yrange[1])]
    )
    _rfcheck(xmid, ymid, yrange, tol) ? xmid :
    let(
         // Force root to be between x0 and midpoint
         y = ymid * ypts[0] < 0 ? [ypts[0], ymid, ypts[1]]
                                : [ypts[1], ymid, ypts[0]],
         x = ymid * ypts[0] < 0 ? [xpts[0], xmid, xpts[1]]
                                : [xpts[1], xmid, xpts[0]],
         v = y[2]*(y[2]-y[0]) - 2*y[1]*(y[1]-y[0])
    )
    v <= 0 ? _rootfind(f,x,y,yrange,tol,i+1)  // Root is between first two points, extra 3rd point doesn't hurt
    :
    let(  // Do quadratic approximation
        B = (x[1]-x[0]) / (y[1]-y[0]),
        C = y*[-1,2,-1] / (y[2]-y[1]) / (y[2]-y[0]),
        newx = x[0] - B * y[0] *(1-C*y[1]),
        newy = f(newx),
        new_yrange = [min(yrange[0],newy), max(yrange[1], newy)],
        // select interval that contains the root by checking sign
        yinterval = newy*y[0] < 0 ? [y[0],newy] : [newy,y[1]],
        xinterval = newy*y[0] < 0 ? [x[0],newx] : [newx,x[1]]
     )
     _rfcheck(newx, newy, new_yrange, tol)
        ? newx
        : _rootfind(f, xinterval, yinterval, new_yrange, tol, i+1);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
