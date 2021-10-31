include <../std.scad>


module test_is_matrix() {
    assert(is_matrix([[2,3,4],[5,6,7],[8,9,10]]));
    assert(is_matrix([[2,3],[5,6],[8,9]],3,2));
    assert(is_matrix([[2,3],[5,6],[8,9]],m=3,n=2));
    assert(is_matrix([[2,3,4],[5,6,7]],m=2,n=3));
    assert(is_matrix([[2,3,4],[5,6,7]],2,3));
    assert(is_matrix([[2,3,4],[5,6,7]],m=2));
    assert(is_matrix([[2,3,4],[5,6,7]],2));
    assert(is_matrix([[2,3,4],[5,6,7]],n=3));
    assert(!is_matrix([[2,3,4],[5,6,7]],m=4));
    assert(!is_matrix([[2,3,4],[5,6,7]],n=5));
    assert(!is_matrix([[2,3],[5,6],[8,9]],m=2,n=3));
    assert(!is_matrix([[2,3,4],[5,6,7]],m=3,n=2));
    assert(!is_matrix([ [2,[3,4]],
                        [4,[5,6]]]));
    assert(!is_matrix([[3,4],[undef,3]]));
    assert(!is_matrix([[3,4],[3,"foo"]]));
    assert(!is_matrix([[3,4],[3,3,2]]));
    assert(!is_matrix([ [3,4],6]));
    assert(!is_matrix(undef));
    assert(!is_matrix(NAN));
    assert(!is_matrix(INF));
    assert(!is_matrix(-5));
    assert(!is_matrix(0));
    assert(!is_matrix(5));
    assert(!is_matrix(""));
    assert(!is_matrix("foo"));
    assert(!is_matrix([3,4,5]));
    assert(!is_matrix([]));
}
test_is_matrix();




module test_ident() {
    assert(ident(3) == [[1,0,0],[0,1,0],[0,0,1]]);
    assert(ident(4) == [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
}
test_ident();





module test_qr_factor() {
  // Check that R is upper triangular
  function is_ut(R) =
     let(bad = [for(i=[1:1:len(R)-1], j=[0:min(i-1, len(R[0])-1)]) if (!approx(R[i][j],0)) 1])
     bad == [];

  // Test the R is upper trianglar, Q is orthogonal and qr=M
  function qrok(qr,M) =
     is_ut(qr[1]) && approx(qr[0]*transpose(qr[0]), ident(len(qr[0]))) && approx(qr[0]*qr[1],M) && qr[2]==ident(len(qr[2]));

  // Test the R is upper trianglar, Q is orthogonal, R diagonal non-increasing and qrp=M
  function qrokpiv(qr,M) =
       is_ut(qr[1])
    && approx(qr[0]*transpose(qr[0]), ident(len(qr[0])))
    && approx(qr[0]*qr[1]*transpose(qr[2]),M)
    && is_decreasing([for(i=[0:1:min(len(qr[1]),len(qr[1][0]))-1]) abs(qr[1][i][i])]);

  
  M = [[1,2,9,4,5],
       [6,7,8,19,10],
       [11,12,13,14,15],
       [1,17,18,19,20],
       [21,22,10,24,25]];
  
  assert(qrok(qr_factor(M),M));
  assert(qrok(qr_factor(select(M,0,3)),select(M,0,3)));
  assert(qrok(qr_factor(transpose(select(M,0,3))),transpose(select(M,0,3))));

  A = [[1,2,9,4,5],
       [6,7,8,19,10],
       [0,0,0,0,0],
       [1,17,18,19,20],
       [21,22,10,24,25]];
  assert(qrok(qr_factor(A),A));

  B = [[1,2,0,4,5],
       [6,7,0,19,10],
       [0,0,0,0,0],
       [1,17,0,19,20],
       [21,22,0,24,25]];

  assert(qrok(qr_factor(B),B));
  assert(qrok(qr_factor([[7]]), [[7]]));
  assert(qrok(qr_factor([[1,2,3]]), [[1,2,3]]));
  assert(qrok(qr_factor([[1],[2],[3]]), [[1],[2],[3]]));


  assert(qrokpiv(qr_factor(M,pivot=true),M));
  assert(qrokpiv(qr_factor(select(M,0,3),pivot=true),select(M,0,3)));
  assert(qrokpiv(qr_factor(transpose(select(M,0,3)),pivot=true),transpose(select(M,0,3))));
  assert(qrokpiv(qr_factor(B,pivot=true),B));
  assert(qrokpiv(qr_factor([[7]],pivot=true), [[7]]));
  assert(qrokpiv(qr_factor([[1,2,3]],pivot=true), [[1,2,3]]));
  assert(qrokpiv(qr_factor([[1],[2],[3]],pivot=true), [[1],[2],[3]]));
}
test_qr_factor();


module test_matrix_inverse() {
    assert_approx(matrix_inverse(rot([20,30,40])), [[0.663413948169,0.556670399226,-0.5,0],[-0.47302145844,0.829769465589,0.296198132726,0],[0.579769465589,0.0400087565481,0.813797681349,0],[0,0,0,1]]);
}
test_matrix_inverse();


module test_det2() {
    assert_equal(det2([[6,-2], [1,8]]), 50);
    assert_equal(det2([[4,7], [3,2]]), -13);
    assert_equal(det2([[4,3], [3,4]]), 7);
}
test_det2();


module test_det3() {
    M = [ [6,4,-2], [1,-2,8], [1,5,7] ];
    assert_equal(det3(M), -334);
}
test_det3();


module test_determinant() {
    M = [ [6,4,-2,9], [1,-2,8,3], [1,5,7,6], [4,2,5,1] ];
    assert_equal(determinant(M), 2267);
}
test_determinant();


module test_matrix_trace() {
    M = [ [6,4,-2,9], [1,-2,8,3], [1,5,7,6], [4,2,5,1] ];
    assert_equal(matrix_trace(M), 6-2+7+1);
}
test_matrix_trace();



module test_norm_fro(){
  assert_approx(norm_fro([[2,3,4],[4,5,6]]), 10.29563014098700);

} test_norm_fro();  


module test_linear_solve(){
  M = [[-2,-5,-1,3],
       [3,7,6,2],
       [6,5,-1,-6],
       [-7,1,2,3]];
  assert_approx(linear_solve(M, [-3,43,-11,13]), [1,2,3,4]);
  assert_approx(linear_solve(M, [[-5,8],[18,-61],[4,7],[-1,-12]]), [[1,-2],[1,-3],[1,-4],[1,-5]]);
  assert_approx(linear_solve([[2]],[4]), [2]);
  assert_approx(linear_solve([[2]],[[4,8]]), [[2, 4]]);
  assert_approx(linear_solve(select(M,0,2), [2,4,4]), [   2.254871220604705e+00,
                                                         -8.378819388897780e-01,
                                                          2.330507118860985e-01,
                                                          8.511278195488737e-01]);
  assert_approx(linear_solve(submatrix(M,idx(M),[0:2]), [2,4,4,4]),
                 [-2.457142857142859e-01,
                   5.200000000000000e-01,
                   7.428571428571396e-02]);
  assert_approx(linear_solve([[1,2,3,4]], [2]), [0.066666666666666, 0.13333333333, 0.2, 0.266666666666]);
  assert_approx(linear_solve([[1],[2],[3],[4]], [4,3,2,1]), [2/3]);
  rd = [[-2,-5,-1,3],
        [3,7,6,2],
        [3,7,6,2],
        [-7,1,2,3]];
  assert_equal(linear_solve(rd,[1,2,3,4]),[]);
  assert_equal(linear_solve(select(rd,0,2), [2,4,4]), []);
  assert_equal(linear_solve(transpose(select(rd,0,2)), [2,4,3,4]), []);
}
test_linear_solve();



module test_null_space(){
    assert_equal(null_space([[3,2,1],[3,6,3],[3,9,-3]]),[]);

    function nullcheck(A,dim) =
      let(v=null_space(A))
        len(v)==dim && all_zero(flatten(A*transpose(v)),eps=1e-12);
    
   A = [[-1, 2, -5, 2],[-3,-1,3,-3],[5,0,5,0],[3,-4,11,-4]];
   assert(nullcheck(A,1));

   B = [
        [  4,    1,    8,    6,   -2,    3],
        [ 10,    5,   10,   10,    0,    5],
        [  8,    1,    8,    8,   -6,    1],
        [ -8,   -8,    6,   -1,   -8,   -1],
        [  2,    2,    0,    1,    2,    1],
        [  2,   -3,   10,    6,   -8,    1],
       ];
   assert(nullcheck(B,3));
}
test_null_space();





module test_back_substitute(){
   R = [[12,4,3,2],
        [0,2,-4,2],
        [0,0,4,5],
        [0,0,0,15]];
   assert_approx(back_substitute(R, [1,2,3,3]), [-0.675, 1.8, 0.5, 0.2]);
   assert_approx(back_substitute(R, [6, 3, 3.5, 37], transpose=true), [0.5, 0.5, 1, 2]);
   assert_approx(back_substitute(R, [[38,101],[-6,-16], [31, 71], [45, 105]]), [[1, 4],[2,3],[4,9],[3,7]]);
   assert_approx(back_substitute(R, [[12,48],[8,22],[11,36],[71,164]],transpose=true), [[1, 4],[2,3],[4,9],[3,7]]);
   assert_approx(back_substitute([[2]], [4]), [2]);
   sing1 =[[0,4,3,2],
         [0,3,-4,2],
         [0,0,4,5],
         [0,0,0,15]];
   sing2 =[[12,4,3,2],
         [0,0,-4,2],
         [0,0,4,5],
         [0,0,0,15]];
   sing3 = [[12,4,3,2],
        [0,2,-4,2],
        [0,0,4,5],
        [0,0,0,0]];
   assert_approx(back_substitute(sing1, [1,2,3,4]), []);
   assert_approx(back_substitute(sing2, [1,2,3,4]), []);
   assert_approx(back_substitute(sing3, [1,2,3,4]), []);
}
test_back_substitute();





module test_outer_product(){
  assert_equal(outer_product([1,2,3],[4,5,6]), [[4,5,6],[8,10,12],[12,15,18]]);
  assert_equal(outer_product([1,2],[4,5,6]), [[4,5,6],[8,10,12]]);
  assert_equal(outer_product([9],[7]), [[63]]);
}
test_outer_product();


module test_column() {
    v = [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]];
    assert(column(v,2) == [3, 7, 11, 15]);
    data = [[1,[3,4]], [3, [9,3]], [4, [3,1]]];   // Matrix with non-numeric entries
    assert_equal(column(data,0), [1,3,4]);
    assert_equal(column(data,1), [[3,4],[9,3],[3,1]]);
}
test_column();


// Need decision about behavior for out of bounds ranges, empty ranges
module test_submatrix(){
  M = [[1,2,3,4,5],
       [6,7,8,9,10],
       [11,12,13,14,15],
       [16,17,18,19,20],
       [21,22,23,24,25]];
  assert_equal(submatrix(M,[1:2], [3:4]), [[9,10],[14,15]]);
  assert_equal(submatrix(M,[1], [3,4]), [[9,10]]);
  assert_equal(submatrix(M,1, [3,4]), [[9,10]]);
  assert_equal(submatrix(M, [3,4],1), [[17],[22]]);
  assert_equal(submatrix(M, [1,3],[2,4]), [[8,10],[18,20]]);
  assert_equal(submatrix(M, 1,3), [[9]]);
  A = [[true,    17, "test"],
     [[4,2],   91, false],
     [6,    [3,4], undef]];
  assert_equal(submatrix(A,[0,2],[1,2]),[[17, "test"], [[3, 4], undef]]);
}
test_submatrix();



module test_hstack() {
    M = ident(3);
    v1 = [2,3,4];
    v2 = [5,6,7];
    v3 = [8,9,10];
    a = hstack(v1,v2);   
    b = hstack(v1,v2,v3);
    c = hstack([M,v1,M]);
    d = hstack(column(M,0), submatrix(M,idx(M),[1,2]));
    assert_equal(a,[[2, 5], [3, 6], [4, 7]]);
    assert_equal(b,[[2, 5, 8], [3, 6, 9], [4, 7, 10]]);
    assert_equal(c,[[1, 0, 0, 2, 1, 0, 0], [0, 1, 0, 3, 0, 1, 0], [0, 0, 1, 4, 0, 0, 1]]);
    assert_equal(d,M);
    strmat = [["three","four"], ["five","six"]];
    assert_equal(hstack(strmat,strmat), [["three", "four", "three", "four"], ["five", "six", "five", "six"]]);
    strvec = ["one","two"];
    assert_equal(hstack(strvec,strmat),[["o", "n", "e", "three", "four"], ["t", "w", "o", "five", "six"]]);
}
test_hstack();


module test_block_matrix() {
    A = [[1,2],[3,4]];
    B = ident(2);
    assert_equal(block_matrix([[A,B],[B,A],[A,B]]), [[1,2,1,0],[3,4,0,1],[1,0,1,2],[0,1,3,4],[1,2,1,0],[3,4,0,1]]);
    assert_equal(block_matrix([[A,B],ident(4)]), [[1,2,1,0],[3,4,0,1],[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    text = [["aa","bb"],["cc","dd"]];
    assert_equal(block_matrix([[text,B]]), [["aa","bb",1,0],["cc","dd",0,1]]);
}
test_block_matrix();


module test_diagonal_matrix() {
    assert_equal(diagonal_matrix([1,2,3]), [[1,0,0],[0,2,0],[0,0,3]]);
    assert_equal(diagonal_matrix([1,"c",2]), [[1,0,0],[0,"c",0],[0,0,2]]);
    assert_equal(diagonal_matrix([1,"c",2],"X"), [[1,"X","X"],["X","c","X"],["X","X",2]]);
    assert_equal(diagonal_matrix([[1,1],[2,2],[3,3]], [0,0]), [[ [1,1],[0,0],[0,0]], [[0,0],[2,2],[0,0]], [[0,0],[0,0],[3,3]]]);
}
test_diagonal_matrix();

module test_submatrix_set() {
    test = [[1,2,3,4,5],[6,7,8,9,10],[11,12,13,14,15], [16,17,18,19,20]];
    ragged = [[1,2,3,4,5],[6,7,8,9,10],[11,12], [16,17]];
    assert_equal(submatrix_set(test,[[9,8],[7,6]]), [[9,8,3,4,5],[7,6,8,9,10],[11,12,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,7],[8,6]],1),[[1,2,3,4,5],[9,7,8,9,10],[8,6,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,8],[7,6]],n=1), [[1,9,8,4,5],[6,7,6,9,10],[11,12,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,8],[7,6]],1,2), [[1,2,3,4,5],[6,7,9,8,10],[11,12,7,6,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,8],[7,6]],-1,-1), [[6,2,3,4,5],[6,7,8,9,10],[11,12,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,8],[7,6]],n=4), [[1,2,3,4,9],[6,7,8,9,7],[11,12,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,8],[7,6]],7,7), [[1,2,3,4,5],[6,7,8,9,10],[11,12,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(ragged, [["a","b"],["c","d"]], 1, 1), [[1,2,3,4,5],[6,"a","b",9,10],[11,"c"], [16,17]]);
    assert_equal(submatrix_set(test, [[]]), test);
}
test_submatrix_set();

module test_transpose() {
    assert(transpose([[1,2,3],[4,5,6],[7,8,9]]) == [[1,4,7],[2,5,8],[3,6,9]]);
    assert(transpose([[1,2,3],[4,5,6]]) == [[1,4],[2,5],[3,6]]);
    assert(transpose([[1,2,3],[4,5,6]],reverse=true) == [[6,3], [5,2], [4,1]]);
    assert(transpose([3,4,5]) == [3,4,5]);
}
test_transpose();


