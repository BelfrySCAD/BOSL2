//////////////////////////////////////////////////////////////////////
// LibFile: linalg.scad
//   This file provides linear algebra, with support for matrix construction,
//   solutions to linear systems of equations, QR and Cholesky factorizations, and
//   matrix inverse.  
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Math
// FileSummary: Linear Algebra: solve linear systems, construct and modify matrices.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

// Section: Matrices
//   The matrix, a rectangular array of numbers which represents a linear transformation,
//   is the fundamental object in linear algebra.  In OpenSCAD a matrix is a list of lists of numbers
//   with a rectangular structure.  Because OpenSCAD treats all data the same, most of the functions that
//   index matrices or construct them will work on matrices (lists of lists) whose elements are not numbers but may be
//   arbitrary data: strings, booleans, or even other lists.  It may even be acceptable in some cases if the structure is non-rectangular.
//   Of course, linear algebra computations and solutions require true matrices with rectangular structure, where all the entries are
//   finite numbers.
//   .
//   Matrices in OpenSCAD are lists of row vectors.  However, a potential source of confusion is that OpenSCAD
//   treats vectors as either column vectors or row vectors as demanded by
//   context.  Thus both `v*M` and `M*v` are valid if `M` is square and `v` has the right length.  If you want to multiply
//   `M` on the left by `v` and `w` you can do this with `[v,w]*M` but if you want to multiply on the right side with `v` and `w` as
//   column vectors, you now need to use {{transpose()}} because OpenSCAD doesn't adjust matrices
//   contextually:  `A=M*transpose([v,w])`.  The solutions are now columns of A and you must extract
//   them with {{column()}} or take the transpose of `A`.  


// Section: Matrix testing and display

// Function: is_matrix()
// Synopsis: Check if input is a numeric matrix, optionally of specified size
// Topics: Matrices
// See Also: is_matrix_symmetric(), is_rotation()
// Usage:
//   test = is_matrix(A, [m], [n], [square])
// Description:
//   Returns true if A is a numeric matrix of height m and width n with finite entries.  If m or n
//   are omitted or set to undef then true is returned for any positive dimension.
// Arguments:
//   A = The matrix to test.
//   m = If given, requires the matrix to have this height.
//   n = Is given, requires the matrix to have this width.
//   square = If true, matrix must have height equal to width. Default: false
function is_matrix(A,m,n,square=false) =
   is_list(A)
   && (( is_undef(m) && len(A) ) || len(A)==m)
   && (!square || len(A) == len(A[0]))
   && is_vector(A[0],n)
   && is_consistent(A);


// Function: is_matrix_symmetric()
// Synopsis: Checks if matrix is symmetric
// Topics: Matrices
// See Also: is_matrix(), is_rotation()
// Usage:
//   b = is_matrix_symmetric(A, [eps])
// Description:
//   Returns true if the input matrix is symmetric, meaning it approximately equals its transpose.  
//   The matrix can have arbitrary entries.  
// Arguments:
//   A = matrix to test
//   eps = epsilon for comparing equality.  Default: 1e-12
function is_matrix_symmetric(A,eps=1e-12) =
    approx(A,transpose(A), eps);


// Function: is_rotation()
// Synopsis: Check if a transformation matrix represents a rotation.
// Topics: Affine, Matrices, Transforms
// See Also: is_matrix(), is_matrix_symmetric(), is_rotation()
// Usage:
//   b = is_rotation(A, [dim], [centered])
// Description:
//   Returns true if the input matrix is a square affine matrix that is a rotation around any point,
//   or around the origin if `centered` is true. 
//   The matrix must be 3x3 (representing a 2d transformation) or 4x4 (representing a 3d transformation).
//   You can set `dim` to 2 to require a 2d transform (3x3 matrix) or to 3 to require a 3d transform (4x4 matrix).
// Arguments:
//   A = matrix to test
//   dim = if set, specify dimension in which the transform operates (2 or 3)
//   centered = if true then require rotation to be around the origin.  Default: false
function is_rotation(A,dim,centered=false) =
    let(n=len(A))
    is_matrix(A,square=true)
    && ( n==3 || n==4 && (is_undef(dim) || dim==n-1))
    &&
    (
      let(
          rotpart =  [for(i=[0:n-2]) [for(j=[0:n-2]) A[j][i]]]
      )
      approx(determinant(rotpart),1)
    )
    && 
    (!centered || [for(row=[0:n-2]) if (!approx(A[row][n-1],0)) row]==[]);
  

// Function&Module: echo_matrix()
// Synopsis: Print a matrix neatly to the console.
// Topics: Matrices
// See Also: is_matrix(), is_matrix_symmetric(), is_rotation()
// Usage:
//    echo_matrix(M, [description], [sig], [sep], [eps]);
//    dummy = echo_matrix(M, [description], [sig], [sep], [eps]),
// Description:
//    Display a numerical matrix in a readable columnar format with `sig` significant
//    digits.  Values smaller than eps display as zero.  If you give a description
//    it is displayed at the top.  You can change the space between columns by
//    setting `sep` to a number of spaces, which will use wide figure spaces the same
//    width as digits, or you can set it to any string to separate the columns.
//    Values that are NaN or INF will display as "nan" and "inf".  Values which are
//    otherwise non-numerica display as two dashes.  Note that this includes lists, so
//    a 3D array will display as a list of dashes.  
// Arguments:
//    M = matrix to display, which should be numerical
//    description = optional text to print before the matrix
//    sig = number of digits to display.  Default: 4
//    sep = number of spaces between columns or a text string to separate columns.  Default: 1
//    eps = numbers smaller than this display as zero.  Default: 1e-9
function echo_matrix(M,description,sig=4,sep=1,eps=1e-9) =
  let(
      horiz_line = chr(8213),
      matstr = _format_matrix(M,sig=sig,sep=sep,eps=eps),
      separator = str_join(repeat(horiz_line,10)),
      dummy=echo(str(separator,is_def(description) ? str("  ",description) : ""))
            [for(row=matstr) echo(row)]
  )
  echo(separator);

module echo_matrix(M,description,sig=4,sep=1,eps=1e-9)
{
  dummy = echo_matrix(M,description,sig,sep,eps);
}


// Section: Matrix indexing

// Function: column()
// Synopsis: Extract a column from a matrix.
// Topics: Matrices, List Handling, Arrays
// See Also: select(), slice()
// Usage:
//   list = column(M, i);
// Description:
//   Extracts entry `i` from each list in M, or equivalently column i from the matrix M, and returns it as a vector.  
//   This function will return `undef` at all entry positions indexed by i not found in M.
// Arguments:
//   M = The given list of lists.
//   i = The index to fetch
// Example:
//   M = [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]];
//   a = column(M,2);      // Returns [3, 7, 11, 15]
//   b = column(M,0);      // Returns [1, 5, 9, 13]
//   N = [ [1,2], [3], [4,5], [6,7,8] ];
//   c = column(N,1);      // Returns [1,undef,5,7]
//   data = [[1,[3,4]], [3, [9,3]], [4, [3,1]]];   // Matrix with non-numeric entries
//   d = column(data,0);   // Returns [1,3,4]
//   e = column(data,1);   // Returns [[3,4],[9,3],[3,1]]
function column(M, i) =
    assert( is_list(M), "The input is not a list." )
    assert( is_int(i) && i>=0, "Invalid index")
    [for(row=M) row[i]];


// Function: submatrix()
// Synopsis: Extract a submatrix from a matrix
// Topics: Matrices, Arrays
// See Also: column(), block_matrix(), submatrix_set()
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


// Section: Matrix construction and modification

// Function: ident()
// Synopsis: Return identity matrix.
// Topics: Affine, Matrices, Transforms
// See Also: IDENT, submatrix(), column()
// Usage:
//   mat = ident(n);
// Description:
//   Create an `n` by `n` square identity matrix.
// Arguments:
//   n = The size of the identity matrix square, `n` by `n`.
// Example:
//   mat = ident(3);
//   // Returns:
//   //   [
//   //     [1, 0, 0],
//   //     [0, 1, 0],
//   //     [0, 0, 1]
//   //   ]
// Example:
//   mat = ident(4);
//   // Returns:
//   //   [
//   //     [1, 0, 0, 0],
//   //     [0, 1, 0, 0],
//   //     [0, 0, 1, 0],
//   //     [0, 0, 0, 1]
//   //   ]
function ident(n) = [
    for (i = [0:1:n-1]) [
        for (j = [0:1:n-1]) (i==j)? 1 : 0
    ]
];


// Function: diagonal_matrix()
// Synopsis: Make a diagonal matrix.
// Topics: Affine, Matrices
// See Also: column(), submatrix()
// Usage:
//   mat = diagonal_matrix(diag, [offdiag]);
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


// Function: transpose()
// Synopsis: Transpose a matrix
// Topics: Linear Algebra, Matrices
// See Also: submatrix(), block_matrix(), hstack(), flatten()
// Usage:
//    M = transpose(M, [reverse]);
// Description:
//    Returns the transpose of the given input matrix.  The input can be a matrix with arbitrary entries or
//    a numerical vector.  If you give a vector then transpose returns it unchanged.  
//    When reverse=true, the transpose is done across to the secondary diagonal.  (See example below.)
//    By default, reverse=false.
// Example:
//   M = [
//       [1, 2, 3],
//       [4, 5, 6],
//       [7, 8, 9]
//   ];
//   t = transpose(M);
//   // Returns:
//   // [
//   //     [1, 4, 7], 
//   //     [2, 5, 8], 
//   //     [3, 6, 9]
//   // ]
// Example:
//   M = [
//       [1, 2, 3], 
//       [4, 5, 6]
//   ];
//   t = transpose(M);
//   // Returns:
//   // [
//   //     [1, 4],
//   //     [2, 5],
//   //     [3, 6],
//   // ]
// Example:
//   M = [
//       [1, 2, 3], 
//       [4, 5, 6], 
//       [7, 8, 9]
//   ];
//   t = transpose(M, reverse=true);
//   // Returns:
//   // [
//   //  [9, 6, 3],
//   //  [8, 5, 2],
//   //  [7, 4, 1]
//   // ]
// Example: Transpose on a list of numbers returns the list unchanged
//   transpose([3,4,5]);  // Returns: [3,4,5]
// Example: Transpose on non-numeric input
//   arr = [
//       [  "a",  "b", "c"],
//       [  "d",  "e", "f"],
//       [[1,2],[3,4],[5,6]]
//   ];
//   t = transpose(arr);
//   // Returns:
//   // [
//   //     ["a", "d", [1,2]],
//   //     ["b", "e", [3,4]],
//   //     ["c", "f", [5,6]],
//   // ]

function transpose(M, reverse=false) =
    assert( is_list(M) && len(M)>0, "Input to transpose must be a nonempty list.")
    is_list(M[0])
    ?   let( len0 = len(M[0]) )
        assert([for(a=M) if(!is_list(a) || len(a)!=len0) 1 ]==[], "Input to transpose has inconsistent row lengths." )
        reverse
        ? [for (i=[0:1:len0-1]) 
              [ for (j=[0:1:len(M)-1]) M[len(M)-1-j][len0-1-i] ] ] 
        : [for (i=[0:1:len0-1]) 
              [ for (j=[0:1:len(M)-1]) M[j][i] ] ] 
    :  assert( is_vector(M), "Input to transpose must be a vector or list of lists.")
           M;


// Function: outer_product()
// Synopsis: Compute the outer product of two vectors. 
// Topics: Linear Algebra, Matrices
// See Also: submatrix(), determinant()
// Usage:
//   x = outer_product(u,v);
// Description:
//   Compute the outer product of two vectors, which is a matrix.
// Usage:
//   M = outer_product(u,v);
function outer_product(u,v) =
  assert(is_vector(u) && is_vector(v), "The inputs must be vectors.")
  [for(ui=u) ui*v];

// Function: submatrix_set()
// Synopsis: Takes a matrix as input and change values in a submatrix.
// Topics: Matrices, Arrays
// See Also: column(), submatrix()
// Usage:
//   mat = submatrix_set(M, A, [m], [n]);
// Description:
//   Sets a submatrix of M equal to the matrix A.  By default the top left corner of M is set to A, but
//   you can specify offset coordinates m and n.  If A (as adjusted by m and n) extends beyond the bounds
//   of M then the extra entries are ignored.  You can pass in `A=[[]]`, a null matrix, and M will be
//   returned unchanged.  This function works on arbitrary lists of lists and the input M need not be rectangular in shape.  
// Arguments:
//   M = Original matrix.
//   A = Submatrix of new values to write into M
//   m = Row number of upper-left corner to place A at.  Default: 0
//   n = Column number of upper-left corner to place A at.  Default: 0 
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


// Function: hstack()
// Synopsis: Make a new matrix by stacking matrices horizontally.
// Topics: Matrices, Arrays
// See Also: column(), submatrix(), block_matrix()
// Usage: 
//   A = hstack(M1, M2)
//   A = hstack(M1, M2, M3)
//   A = hstack([M1, M2, M3, ...])
// Description:
//   Constructs a matrix by horizontally "stacking" together compatible matrices or vectors.  Vectors are treated as columsn in the stack.
//   This command is the inverse of `column`.  Note: strings given in vectors are broken apart into lists of characters.  Strings given
//   in matrices are preserved as strings.  If you need to combine vectors of strings use {{list_to_matrix()}} as shown below to convert the
//   vector into a column matrix.  Also note that vertical stacking can be done directly with concat.  
// Arguments:
//   M1 = If given with other arguments, the first matrix (or vector) to stack.  If given alone, a list of matrices/vectors to stack. 
//   M2 = Second matrix/vector to stack
//   M3 = Third matrix/vector to stack.
// Example:
//   M = ident(3);
//   v1 = [2,3,4];
//   v2 = [5,6,7];
//   v3 = [8,9,10];
//   a = hstack(v1,v2);     // Returns [[2, 5], [3, 6], [4, 7]]
//   b = hstack(v1,v2,v3);  // Returns [[2, 5,  8],
//                          //          [3, 6,  9],
//                          //          [4, 7, 10]]
//   c = hstack([M,v1,M]);  // Returns [[1, 0, 0, 2, 1, 0, 0],
//                          //          [0, 1, 0, 3, 0, 1, 0],
//                          //          [0, 0, 1, 4, 0, 0, 1]]
//   d = hstack(column(M,0), submatrix(M,idx(M),[1 2]));  // Returns M
//   strvec = ["one","two"];
//   strmat = [["three","four"], ["five","six"]];
//   e = hstack(strvec,strvec); // Returns [["o", "n", "e", "o", "n", "e"],
//                              //          ["t", "w", "o", "t", "w", "o"]]
//   f = hstack(list_to_matrix(strvec,1), list_to_matrix(strvec,1));
//                              // Returns [["one", "one"],
//                              //          ["two", "two"]]
//   g = hstack(strmat,strmat); //  Returns: [["three", "four", "three", "four"],
//                              //            [ "five",  "six",  "five",  "six"]]
function hstack(M1, M2, M3) =
    (M3!=undef)? hstack([M1,M2,M3]) : 
    (M2!=undef)? hstack([M1,M2]) :
    assert(all([for(v=M1) is_list(v)]), "One of the inputs to hstack is not a list")
    let(
        minlen = min_length(M1),
        maxlen = max_length(M1)
    )
    assert(minlen==maxlen, "Input vectors to hstack must have the same length")
    [for(row=[0:1:minlen-1])
        [for(matrix=M1)
           each matrix[row]
        ]
    ];


// Function: block_matrix()
// Synopsis: Make a new matrix from a block of matrices. 
// Topics: Matrices, Arrays
// See Also: column(), submatrix()
// Usage:
//    bmat = block_matrix([[M11, M12,...],[M21, M22,...], ... ]);
// Description:
//    Create a block matrix by supplying a matrix of matrices, which will
//    be combined into one unified matrix.  Every matrix in one row
//    must have the same height, and the combined width of the matrices
//    in each row must be equal. Strings will stay strings. 
// Example:
//  A = [[1,2],
//       [3,4]];
//  B = ident(2);
//  C = block_matrix([[A,B],[B,A],[A,B]]);
//      // Returns:
//      //        [[1, 2, 1, 0],
//      //         [3, 4, 0, 1],
//      //         [1, 0, 1, 2],
//      //         [0, 1, 3, 4],
//      //         [1, 2, 1, 0],
//      //         [3, 4, 0, 1]]);
//  D = block_matrix([[A,B], ident(4)]);
//      // Returns:
//      //        [[1, 2, 1, 0],
//      //         [3, 4, 0, 1],
//      //         [1, 0, 0, 0],
//      //         [0, 1, 0, 0],
//      //         [0, 0, 1, 0],
//      //         [0, 0, 0, 1]]);
//  E = [["one", "two"], [3,4]];
//  F = block_matrix([[E,E]]);
//      // Returns:
//      //        [["one", "two", "one", "two"],
//      //         [    3,     4,     3,     4]]
function block_matrix(M) =
    let(
        bigM = [for(bigrow = M) each hstack(bigrow)],
        len0 = len(bigM[0]),
        badrows = [for(row=bigM) if (len(row)!=len0) 1]
    )
    assert(badrows==[], "Inconsistent or invalid input")
    bigM;


// Section: Solving Linear Equations and Matrix Factorizations

// Function: linear_solve()
// Synopsis: Solve Ax=b or, for overdetermined case, solve the least square problem. 
// Topics: Matrices, Linear Algebra
// See Also: linear_solve3(), matrix_inverse(), rot_inverse(), back_substitute(), cholesky()
// Usage:
//   solv = linear_solve(A,b,[pivot])
// Description:
//   Solves the linear system Ax=b.  If `A` is square and non-singular the unique solution is returned.  If `A` is overdetermined
//   the least squares solution is returned. If `A` is underdetermined, the minimal norm solution is returned.
//   If `A` is rank deficient or singular then linear_solve returns `[]`.  If `b` is a matrix that is compatible with `A`
//   then the problem is solved for the matrix valued right hand side and a matrix is returned.  Note that if you 
//   want to solve Ax=b1 and Ax=b2 that you need to form the matrix `transpose([b1,b2])` for the right hand side and then
//   transpose the returned value.  The solution is computed using QR factorization.  If `pivot` is set to true (the default) then
//   pivoting is used in the QR factorization, which is slower but expected to be more accurate.
// Arguments:
//   A = Matrix describing the linear system, which need not be square
//   b = right hand side for linear system, which can be a matrix to solve several cases simultaneously.  Must be consistent with A.
//   pivot = if true use pivoting when computing the QR factorization.  Default: true
function linear_solve(A,b,pivot=true) =
    assert(is_matrix(A), "Input should be a matrix.")
    let(
        m = len(A),
        n = len(A[0])
    )
    assert(is_vector(b,m) || is_matrix(b,m),"Invalid right hand side or incompatible with the matrix")
    let (
        qr = m<n? qr_factor(transpose(A),pivot) : qr_factor(A,pivot),
        maxdim = max(n,m),
        mindim = min(n,m),
        Q = submatrix(qr[0],[0:maxdim-1], [0:mindim-1]),
        R = submatrix(qr[1],[0:mindim-1], [0:mindim-1]),
        P = qr[2],
        zeros = [for(i=[0:mindim-1]) if (approx(R[i][i],0)) i]
    )
    zeros != [] ? [] :
    m<n ? Q*back_substitute(R,transpose(P)*b,transpose=true) // Too messy to avoid input checks here
        : P*_back_substitute(R, transpose(Q)*b);             // Calling internal version skips input checks


// Function: linear_solve3()
// Synopsis: Fast solution to Ax=b where A is 3x3.
// Topics: Matrices, Linear Algebra
// See Also: linear_solve(), matrix_inverse(), rot_inverse(), back_substitute(), cholesky()
// Usage:
//   x = linear_solve3(A,b)
// Description:
//   Fast solution to a 3x3 linear system using Cramer's rule (which appears to be the fastest
//   method in OpenSCAD).  The input `A` must be a 3x3 matrix.  Returns undef if `A` is singular.
//   The input `b` must be a 3-vector.  Note that Cramer's rule is not a stable algorithm, so for
//   the highest accuracy on ill-conditioned problems you may want to use the general solver, which is about ten times slower.
// Arguments:
//   A = 3x3 matrix for linear system
//   b = length 3 vector, right hand side of linear system
function linear_solve3(A,b) =
  // Arg sanity checking adds 7% overhead
  assert(b*0==[0,0,0], "Input b must be a 3-vector")
  assert(A*0==[[0,0,0],[0,0,0],[0,0,0]],"Input A must be a 3x3 matrix")
  let(
      Az = [for(i=[0:2])[A[i][0], A[i][1], b[i]]],
      Ay = [for(i=[0:2])[A[i][0], b[i], A[i][2]]],
      Ax = [for(i=[0:2])[b[i], A[i][1], A[i][2]]],
      detA = det3(A)
  )
  detA==0 ? undef : [det3(Ax), det3(Ay), det3(Az)] / detA;


// Function: matrix_inverse()
// Synopsis: General matrix inverse. 
// Topics: Matrices, Linear Algebra
// See Also: linear_solve(), linear_solve3(), matrix_inverse(), rot_inverse(), back_substitute(), cholesky()
// Usage:
//    mat = matrix_inverse(A)
// Description:
//    Compute the matrix inverse of the square matrix `A`.  If `A` is singular, returns `undef`.
//    Note that if you just want to solve a linear system of equations you should NOT use this function.
//    Instead use {{linear_solve()}}, or use {{qr_factor()}}.  The computation
//    will be faster and more accurate.  
function matrix_inverse(A) =
    assert(is_matrix(A) && len(A)==len(A[0]),"Input to matrix_inverse() must be a square matrix")
    linear_solve(A,ident(len(A)));


// Function: rot_inverse()
// Synopsis: Invert 2d or 3d rotation transformations. 
// Topics: Matrices, Linear Algebra, Affine
// See Also: linear_solve(), linear_solve3(), matrix_inverse(), rot_inverse(), back_substitute(), cholesky()
// Usage:
//   B = rot_inverse(A)
// Description:
//   Inverts a 2d (3x3) or 3d (4x4) rotation matrix.  The matrix can be a rotation around any center,
//   so it may include a translation.  This is faster and likely to be more accurate than using `matrix_inverse()`.  
function rot_inverse(T) =
    assert(is_matrix(T,square=true),"Matrix must be square")
    let( n = len(T))
    assert(n==3 || n==4, "Matrix must be 3x3 or 4x4")
    let(
        rotpart =  [for(i=[0:n-2]) [for(j=[0:n-2]) T[j][i]]],
        transpart = [for(row=[0:n-2]) T[row][n-1]]
    )
    assert(approx(determinant(T),1),"Matrix is not a rotation")
    concat(hstack(rotpart, -rotpart*transpart),[[for(i=[2:n]) 0, 1]]);




// Function: null_space()
// Synopsis: Return basis for the null space of A. 
// Topics: Matrices, Linear Algebra
// See Also: linear_solve(), linear_solve3(), matrix_inverse(), rot_inverse(), back_substitute(), cholesky()
// Usage:
//   x = null_space(A)
// Description:
//   Returns an orthonormal basis for the null space of `A`, namely the vectors {x} such that Ax=0.
//   If the null space is just the origin then returns an empty list. 
function null_space(A,eps=1e-12) =
    assert(is_matrix(A))
    let(
        Q_R = qr_factor(transpose(A),pivot=true),
        R = Q_R[1],
        zrows = [for(i=idx(R)) if (all_zero(R[i],eps)) i]
    )
    len(zrows)==0 ? [] :
    select(transpose(Q_R[0]), zrows);

// Function: qr_factor()
// Synopsis: Compute QR factorization of a matrix.
// Topics: Matrices, Linear Algebra
// See Also: linear_solve(), linear_solve3(), matrix_inverse(), rot_inverse(), back_substitute(), cholesky()
// Usage:
//   qr = qr_factor(A,[pivot]);
// Description:
//   Calculates the QR factorization of the input matrix A and returns it as the list [Q,R,P].  This factorization can be
//   used to solve linear systems of equations.  The factorization is `A = Q*R*transpose(P)`.  If pivot is false (the default)
//   then P is the identity matrix and A = Q*R.  If pivot is true then column pivoting results in an R matrix where the diagonal
//   is non-decreasing.  The use of pivoting is supposed to increase accuracy for poorly conditioned problems, and is necessary
//   for rank estimation or computation of the null space, but it may be slower.  
function qr_factor(A, pivot=false) =
    assert(is_matrix(A), "Input must be a matrix." )
    let(
        m = len(A),
        n = len(A[0])
    )
    let(
        qr = _qr_factor(A, Q=ident(m),P=ident(n), pivot=pivot, col=0, m = m, n = n),
        Rzero = let( R = qr[1]) [
            for(i=[0:m-1]) [
                let( ri = R[i] )
                for(j=[0:n-1]) i>j ? 0 : ri[j]
            ]
        ]
    ) [qr[0], Rzero, qr[2]];

function _qr_factor(A,Q,P, pivot, col, m, n) =
    col >= min(m-1,n) ? [Q,A,P] :
    let(
        swap = !pivot ? 1
             : _swap_matrix(n,col,col+max_index([for(i=[col:n-1]) sqr([for(j=[col:m-1]) A[j][i]])])),
        A = pivot ? A*swap : A,
        x = [for(i=[col:1:m-1]) A[i][col]],
        alpha = (x[0]<=0 ? 1 : -1) * norm(x),
        u = x - concat([alpha],repeat(0,m-1)),
        v = alpha==0 ? u : u / norm(u),
        Qc = ident(len(x)) - 2*outer_product(v,v),
        Qf = [for(i=[0:m-1]) [for(j=[0:m-1]) i<col || j<col ? (i==j ? 1 : 0) : Qc[i-col][j-col]]]
    )
    _qr_factor(Qf*A, Q*Qf, P*swap, pivot, col+1, m, n);

// Produces an n x n matrix that swaps column i and j (when multiplied on the right)
function _swap_matrix(n,i,j) =
  assert(i<n && j<n && i>=0 && j>=0, "Swap indices out of bounds")
  [for(y=[0:n-1]) [for (x=[0:n-1])
     x==i ? (y==j ? 1 : 0)
   : x==j ? (y==i ? 1 : 0)
   : x==y ? 1 : 0]];



// Function: back_substitute()
// Synopsis: Solve an upper triangular system, Rx=b.  
// Topics: Matrices, Linear Algebra
// See Also: linear_solve(), linear_solve3(), matrix_inverse(), rot_inverse(), back_substitute(), cholesky()
// Usage:
//   x = back_substitute(R, b, [transpose]);
// Description:
//   Solves the problem Rx=b where R is an upper triangular square matrix.  The lower triangular entries of R are
//   ignored.  If transpose==true then instead solve transpose(R)*x=b.
//   You can supply a compatible matrix b and it will produce the solution for every column of b.  Note that if you want to
//   solve Rx=b1 and Rx=b2 you must set b to transpose([b1,b2]) and then take the transpose of the result.  If the matrix
//   is singular (e.g. has a zero on the diagonal) then it returns [].  
function back_substitute(R, b, transpose = false) =
    assert(is_matrix(R, square=true))
    let(n=len(R))
    assert(is_vector(b,n) || is_matrix(b,n),str("R and b are not compatible in back_substitute ",n, len(b)))
    transpose
      ? reverse(_back_substitute(transpose(R, reverse=true), reverse(b)))  
      : _back_substitute(R,b);

function _back_substitute(R, b, x=[]) =
    let(n=len(R))
    len(x) == n ? x
    : let(ind = n - len(x) - 1)
      R[ind][ind] == 0 ? []
    : let(
          newvalue = len(x)==0
            ? b[ind]/R[ind][ind]
            : (b[ind]-list_tail(R[ind],ind+1) * x)/R[ind][ind]
      )
      _back_substitute(R, b, concat([newvalue],x));



// Function: cholesky()
// Synopsis: Compute the Cholesky factorization of a matrix. 
// Topics: Matrices, Linear Algebra
// See Also: linear_solve(), linear_solve3(), matrix_inverse(), rot_inverse(), back_substitute(), cholesky()
// Usage:
//   L = cholesky(A);
// Description:
//   Compute the cholesky factor, L, of the symmetric positive definite matrix A.
//   The matrix L is lower triangular and `L * transpose(L) = A`.  If the A is
//   not symmetric then an error is displayed.  If the matrix is symmetric but
//   not positive definite then undef is returned.  
function cholesky(A) =
  assert(is_matrix(A,square=true),"A must be a square matrix")
  assert(is_matrix_symmetric(A),"Cholesky factorization requires a symmetric matrix")
  _cholesky(A,ident(len(A)), len(A));

function _cholesky(A,L,n) = 
    A[0][0]<0 ? undef :     // Matrix not positive definite
    len(A) == 1 ? submatrix_set(L,[[sqrt(A[0][0])]], n-1,n-1):
    let(
        i = n+1-len(A)
    )
    let(
        sqrtAii = sqrt(A[0][0]),
        Lnext = [for(j=[0:n-1])
                  [for(k=[0:n-1])
                      j<i-1 || k<i-1 ?  (j==k ? 1 : 0)
                     : j==i-1 && k==i-1 ? sqrtAii
                     : j==i-1 ? 0
                     : k==i-1 ? A[j-(i-1)][0]/sqrtAii
                     : j==k ? 1 : 0]],
        Anext = submatrix(A,[1:n-1], [1:n-1]) - outer_product(list_tail(A[0]), list_tail(A[0]))/A[0][0]
    )
    _cholesky(Anext,L*Lnext,n);


// Section: Matrix Properties: Determinants, Norm, Trace

// Function: det2()
// Synopsis: Compute determinant of 2x2 matrix.
// Topics: Matrices, Linear Algebra
// See Also: det2(), det3(), det4(), determinant(), norm_fro(), matrix_trace()
// Usage:
//   d = det2(M);
// Description:
//   Rturns the determinant for the given 2x2 matrix.
// Arguments:
//   M = The 2x2 matrix to get the determinant of.
// Example:
//   M = [ [6,-2], [1,8] ];
//   det = det2(M);  // Returns: 50
function det2(M) = 
    assert(is_def(M) && M*0==[[0,0],[0,0]], "Expected square matrix (2x2)")
    cross(M[0],M[1]);


// Function: det3()
// Synopsis: Compute determinant of 3x3 matrix.
// Topics: Matrices, Linear Algebra
// See Also: det2(), det3(), det4(), determinant(), norm_fro(), matrix_trace()
// Usage:
//   d = det3(M);
// Description:
//   Returns the determinant for the given 3x3 matrix.
// Arguments:
//   M = The 3x3 square matrix to get the determinant of.
// Example:
//   M = [ [6,4,-2], [1,-2,8], [1,5,7] ];
//   det = det3(M);  // Returns: -334
function det3(M) =
    assert(is_def(M) && M*0==[[0,0,0],[0,0,0],[0,0,0]], "Expected square matrix (3x3).")
    M[0][0] * (M[1][1]*M[2][2]-M[2][1]*M[1][2]) -
    M[1][0] * (M[0][1]*M[2][2]-M[2][1]*M[0][2]) +
    M[2][0] * (M[0][1]*M[1][2]-M[1][1]*M[0][2]);

// Function: det4()
// Synopsis: Compute determinant of 4x4 matrix. 
// Topics: Matrices, Linear Algebra
// See Also: det2(), det3(), det4(), determinant(), norm_fro(), matrix_trace()
// Usage:
//   d = det4(M);
// Description:
//   Returns the determinant for the given 4x4 matrix.
// Arguments:
//   M = The 4x4 square matrix to get the determinant of.
// Example:
//   M = [ [6,4,-2,1], [1,-2,8,-3], [1,5,7,4], [2,3,4,7] ];
//   det = det4(M);  // Returns: -1773
function det4(M) =
    assert(is_def(M) && M*0==[[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], "Expected square matrix (4x4).")
    M[0][0]*M[1][1]*M[2][2]*M[3][3] + M[0][0]*M[1][2]*M[2][3]*M[3][1] + M[0][0]*M[1][3]*M[2][1]*M[3][2]
    + M[0][1]*M[1][0]*M[2][3]*M[3][2] + M[0][1]*M[1][2]*M[2][0]*M[3][3] + M[0][1]*M[1][3]*M[2][2]*M[3][0]
    + M[0][2]*M[1][0]*M[2][1]*M[3][3] + M[0][2]*M[1][1]*M[2][3]*M[3][0] + M[0][2]*M[1][3]*M[2][0]*M[3][1]
    + M[0][3]*M[1][0]*M[2][2]*M[3][1] + M[0][3]*M[1][1]*M[2][0]*M[3][2] + M[0][3]*M[1][2]*M[2][1]*M[3][0]
    - M[0][0]*M[1][1]*M[2][3]*M[3][2] - M[0][0]*M[1][2]*M[2][1]*M[3][3] - M[0][0]*M[1][3]*M[2][2]*M[3][1]
    - M[0][1]*M[1][0]*M[2][2]*M[3][3] - M[0][1]*M[1][2]*M[2][3]*M[3][0] - M[0][1]*M[1][3]*M[2][0]*M[3][2]
    - M[0][2]*M[1][0]*M[2][3]*M[3][1] - M[0][2]*M[1][1]*M[2][0]*M[3][3] - M[0][2]*M[1][3]*M[2][1]*M[3][0]
    - M[0][3]*M[1][0]*M[2][1]*M[3][2] - M[0][3]*M[1][1]*M[2][2]*M[3][0] - M[0][3]*M[1][2]*M[2][0]*M[3][1];

// Function: determinant()
// Synopsis: compute determinant of an arbitrary square matrix. 
// Topics: Matrices, Linear Algebra
// See Also: det2(), det3(), det4(), determinant(), norm_fro(), matrix_trace()
// Usage:
//   d = determinant(M);
// Description:
//   Returns the determinant for the given square matrix.
// Arguments:
//   M = The NxN square matrix to get the determinant of.
// Example:
//   M = [ [6,4,-2,9], [1,-2,8,3], [1,5,7,6], [4,2,5,1] ];
//   det = determinant(M);  // Returns: 2267
function determinant(M) =
    assert(is_list(M), "Input must be a square matrix." )  
    len(M)==1? M[0][0] :
    len(M)==2? det2(M) :
    len(M)==3? det3(M) :
    len(M)==4? det4(M) :
    assert(is_matrix(M, square=true), "Input must be a square matrix." )    
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


// Function: norm_fro()
// Synopsis: Compute Frobenius norm of a matrix
// Topics: Matrices, Linear Algebra
// See Also: det2(), det3(), det4(), determinant(), norm_fro(), matrix_trace()
// Usage:
//    norm_fro(A)
// Description:
//    Computes frobenius norm of input matrix.  The frobenius norm is the square root of the sum of the
//    squares of all of the entries of the matrix.  On vectors it is the same as the usual 2-norm.
//    This is an easily computed norm that is convenient for comparing two matrices.  
function norm_fro(A) =
    assert(is_matrix(A) || is_vector(A))
    norm(flatten(A));


// Function: matrix_trace()
// Synopsis: Compute the trace of a square matrix. 
// Topics: Matrices, Linear Algebra
// See Also: det2(), det3(), det4(), determinant(), norm_fro(), matrix_trace()
// Usage:
//   matrix_trace(M)
// Description:
//   Computes the trace of a square matrix, the sum of the entries on the diagonal.  
function matrix_trace(M) =
   assert(is_matrix(M,square=true), "Input to trace must be a square matrix")
   [for(i=[0:1:len(M)-1])1] * [for(i=[0:1:len(M)-1]) M[i][i]];



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap

