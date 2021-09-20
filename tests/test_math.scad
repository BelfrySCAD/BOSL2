include <../std.scad>

// Simple Calculations

module test_quant() {
    assert_equal(quant(-4,3), -3);
    assert_equal(quant(-3,3), -3);
    assert_equal(quant(-2,3), -3);
    assert_equal(quant(-1,3), 0);
    assert_equal(quant(0,3), 0);
    assert_equal(quant(1,3), 0);
    assert_equal(quant(2,3), 3);
    assert_equal(quant(3,3), 3);
    assert_equal(quant(4,3), 3);
    assert_equal(quant(7,3), 6);
    assert_equal(quant(12,2.5), 12.5);
    assert_equal(quant(11,2.5), 10.0);
    assert_equal(quant([12,13,13.1,14,14.1,15,16],4), [12,12,12,16,16,16,16]);
    assert_equal(quant([9,10,10.4,10.5,11,12],3), [9,9,9,12,12,12]);
    assert_equal(quant([[9,10,10.4],[10.5,11,12]],3), [[9,9,9],[12,12,12]]);
}
test_quant();


module test_quantdn() {
    assert_equal(quantdn(-4,3), -6);
    assert_equal(quantdn(-3,3), -3);
    assert_equal(quantdn(-2,3), -3);
    assert_equal(quantdn(-1,3), -3);
    assert_equal(quantdn(0,3), 0);
    assert_equal(quantdn(1,3), 0);
    assert_equal(quantdn(2,3), 0);
    assert_equal(quantdn(3,3), 3);
    assert_equal(quantdn(4,3), 3);
    assert_equal(quantdn(7,3), 6);
    assert_equal(quantdn(12,2.5), 10.0);
    assert_equal(quantdn(11,2.5), 10.0);
    assert_equal(quantdn([12,13,13.1,14,14.1,15,16],4), [12,12,12,12,12,12,16]);
    assert_equal(quantdn([9,10,10.4,10.5,11,12],3), [9,9,9,9,9,12]);
    assert_equal(quantdn([[9,10,10.4],[10.5,11,12]],3), [[9,9,9],[9,9,12]]);
}
test_quantdn();


module test_quantup() {
    assert_equal(quantup(-4,3), -3);
    assert_equal(quantup(-3,3), -3);
    assert_equal(quantup(-2,3), 0);
    assert_equal(quantup(-1,3), 0);
    assert_equal(quantup(0,3), 0);
    assert_equal(quantup(1,3), 3);
    assert_equal(quantup(2,3), 3);
    assert_equal(quantup(3,3), 3);
    assert_equal(quantup(4,3), 6);
    assert_equal(quantup(7,3), 9);
    assert_equal(quantup(12,2.5), 12.5);
    assert_equal(quantup(11,2.5), 12.5);
    assert_equal(quantup([12,13,13.1,14,14.1,15,16],4), [12,16,16,16,16,16,16]);
    assert_equal(quantup([9,10,10.4,10.5,11,12],3), [9,12,12,12,12,12]);
    assert_equal(quantup([[9,10,10.4],[10.5,11,12]],3), [[9,12,12],[12,12,12]]);
}
test_quantup();


module test_constrain() {
    assert_equal(constrain(-2,-1,1), -1);
    assert_equal(constrain(-1.75,-1,1), -1);
    assert_equal(constrain(-1,-1,1), -1);
    assert_equal(constrain(-0.75,-1,1), -0.75);
    assert_equal(constrain(0,-1,1), 0);
    assert_equal(constrain(0.75,-1,1), 0.75);
    assert_equal(constrain(1,-1,1), 1);
    assert_equal(constrain(1.75,-1,1), 1);
    assert_equal(constrain(2,-1,1), 1);
}
test_constrain();


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


module test_all_zero() {
    assert(all_zero(0));
    assert(all_zero([0,0,0]));
    assert(all_zero([[0,0,0],[0,0]]));
    assert(all_zero([EPSILON/2,EPSILON/2,EPSILON/2]));
    assert(!all_zero(1e-3));
    assert(!all_zero([0,0,1e-3]));
    assert(!all_zero([EPSILON*10,0,0]));
    assert(!all_zero([0,EPSILON*10,0]));
    assert(!all_zero([0,0,EPSILON*10]));
    assert(!all_zero(true));
    assert(!all_zero(false));
    assert(!all_zero(INF));
    assert(!all_zero(-INF));
    assert(!all_zero(NAN));
    assert(!all_zero("foo"));
    assert(!all_zero([]));
    assert(!all_zero([0:1:2]));
}
test_all_zero();


module test_all_nonzero() {
    assert(!all_nonzero(0));
    assert(!all_nonzero([0,0,0]));
    assert(!all_nonzero([[0,0,0],[0,0]]));
    assert(!all_nonzero([EPSILON/2,EPSILON/2,EPSILON/2]));
    assert(all_nonzero(1e-3));
    assert(!all_nonzero([0,0,1e-3]));
    assert(!all_nonzero([EPSILON*10,0,0]));
    assert(!all_nonzero([0,EPSILON*10,0]));
    assert(!all_nonzero([0,0,EPSILON*10]));
    assert(all_nonzero([1e-3,1e-3,1e-3]));
    assert(all_nonzero([EPSILON*10,EPSILON*10,EPSILON*10]));
    assert(!all_nonzero(true));
    assert(!all_nonzero(false));
    assert(!all_nonzero(INF));
    assert(!all_nonzero(-INF));
    assert(!all_nonzero(NAN));
    assert(!all_nonzero("foo"));
    assert(!all_nonzero([]));
    assert(!all_nonzero([0:1:2]));
}
test_all_nonzero();


module test_all_positive() {
    assert(!all_positive(-2));
    assert(!all_positive(0));
    assert(all_positive(2));
    assert(!all_positive([0,0,0]));
    assert(!all_positive([0,1,2]));
    assert(all_positive([3,1,2]));
    assert(!all_positive([3,-1,2]));
    assert(!all_positive([]));
    assert(!all_positive(true));
    assert(!all_positive(false));
    assert(!all_positive("foo"));
    assert(!all_positive([0:1:2]));
}
test_all_positive();


module test_all_negative() {
    assert(all_negative(-2));
    assert(!all_negative(0));
    assert(!all_negative(2));
    assert(!all_negative([0,0,0]));
    assert(!all_negative([0,1,2]));
    assert(!all_negative([3,1,2]));
    assert(!all_negative([3,-1,2]));
    assert(all_negative([-3,-1,-2]));
    assert(!all_negative([-3,1,-2]));
    assert(all_negative([[-5,-7],[-3,-1,-2]]));
    assert(!all_negative([[-5,-7],[-3,1,-2]]));
    assert(!all_negative([]));
    assert(!all_negative(true));
    assert(!all_negative(false));
    assert(!all_negative("foo"));
    assert(!all_negative([0:1:2]));
}
test_all_negative();


module test_all_nonpositive() {
    assert(all_nonpositive(-2));
    assert(all_nonpositive(0));
    assert(!all_nonpositive(2));
    assert(all_nonpositive([0,0,0]));
    assert(!all_nonpositive([0,1,2]));
    assert(all_nonpositive([0,-1,-2]));
    assert(!all_nonpositive([3,1,2]));
    assert(!all_nonpositive([3,-1,2]));
    assert(!all_nonpositive([]));
    assert(!all_nonpositive(true));
    assert(!all_nonpositive(false));
    assert(!all_nonpositive("foo"));
    assert(!all_nonpositive([0:1:2]));
}
test_all_nonpositive();


module test_all_nonnegative() {
    assert(!all_nonnegative(-2));
    assert(all_nonnegative(0));
    assert(all_nonnegative(2));
    assert(all_nonnegative([0,0,0]));
    assert(all_nonnegative([0,1,2]));
    assert(all_nonnegative([3,1,2]));
    assert(!all_nonnegative([3,-1,2]));
    assert(!all_nonnegative([-3,-1,-2]));
    assert(!all_nonnegative([[-5,-7],[-3,-1,-2]]));
    assert(!all_nonnegative([[-5,-7],[-3,1,-2]]));
    assert(!all_nonnegative([[5,7],[3,-1,2]]));
    assert(all_nonnegative([[5,7],[3,1,2]]));
    assert(!all_nonnegative([]));
    assert(!all_nonnegative(true));
    assert(!all_nonnegative(false));
    assert(!all_nonnegative("foo"));
    assert(!all_nonnegative([0:1:2]));
}
test_all_nonnegative();


module test_all_integer() {
    assert(!all_integer(undef));
    assert(!all_integer(true));
    assert(!all_integer(false));
    assert(!all_integer(4.3));
    assert(!all_integer("foo"));
    assert(!all_integer([]));
    assert(!all_integer([3,4.1,5,7]));
    assert(!all_integer([[1,2,3],[4,5,6],[7,8]]));
    assert(all_integer(-4));
    assert(all_integer(0));
    assert(all_integer(5));
    assert(all_integer([-3]));
    assert(all_integer([0]));
    assert(all_integer([3]));
    assert(all_integer([2,-4,0,5,7,9876543210]));
}
test_all_integer();


module test_approx() {
    assert_equal(approx(PI, 3.141592653589793236), true);
    assert_equal(approx(PI, 3.1415926), false);
    assert_equal(approx(PI, 3.1415926, eps=1e-6), true);
    assert_equal(approx(-PI, -3.141592653589793236), true);
    assert_equal(approx(-PI, -3.1415926), false);
    assert_equal(approx(-PI, -3.1415926, eps=1e-6), true);
    assert_equal(approx(1/3, 0.3333333333), true);
    assert_equal(approx(-1/3, -0.3333333333), true);
    assert_equal(approx(10*[cos(30),sin(30)], 10*[sqrt(3)/2, 1/2]), true);
    assert_equal(approx([1,[1,undef]], [1+1e-12,[1,true]]), false);
    assert_equal(approx([1,[1,undef]], [1+1e-12,[1,undef]]), true);
}
test_approx();


module test_min_index() {
    vals = rands(-100,100,100,seed=75);
    minval = min(vals);
    minidx = min_index(vals);
    assert_equal(vals[minidx], minval);
    assert_equal(min_index([3,4,5,6]), 0);
    assert_equal(min_index([4,3,5,6]), 1);
    assert_equal(min_index([4,5,3,6]), 2);
    assert_equal(min_index([4,5,6,3]), 3);
    assert_equal(min_index([6,5,4,3]), 3);
    assert_equal(min_index([6,3,4,5]), 1);
    assert_equal(min_index([-56,72,-874,5]), 2);
}
test_min_index();


module test_max_index() {
    vals = rands(-100,100,100,seed=97);
    maxval = max(vals);
    maxidx = max_index(vals);
    assert_equal(vals[maxidx], maxval);
    assert_equal(max_index([3,4,5,6]), 3);
    assert_equal(max_index([3,4,6,5]), 2);
    assert_equal(max_index([3,6,4,5]), 1);
    assert_equal(max_index([6,3,4,5]), 0);
    assert_equal(max_index([5,6,4,3]), 1);
    assert_equal(max_index([-56,72,-874,5]), 1);
}
test_max_index();


module test_posmod() {
    assert_equal(posmod(-5,3), 1);
    assert_equal(posmod(-4,3), 2);
    assert_equal(posmod(-3,3), 0);
    assert_equal(posmod(-2,3), 1);
    assert_equal(posmod(-1,3), 2);
    assert_equal(posmod(0,3), 0);
    assert_equal(posmod(1,3), 1);
    assert_equal(posmod(2,3), 2);
    assert_equal(posmod(3,3), 0);
}
test_posmod();


module test_modang() {
    assert_equal(modang(-700), 20);
    assert_equal(modang(-270), 90);
    assert_equal(modang(-120), -120);
    assert_equal(modang(120), 120);
    assert_equal(modang(270), -90);
    assert_equal(modang(700), -20);
}
test_modang();


module test_sqr() {
    assert_equal(sqr(-3), 9);
    assert_equal(sqr(0), 0);
    assert_equal(sqr(1), 1);
    assert_equal(sqr(2), 4);
    assert_equal(sqr(2.5), 6.25);
    assert_equal(sqr(3), 9);
    assert_equal(sqr(16), 256);
    assert_equal(sqr([2,3,4]), 29);
    assert_equal(sqr([[2,3,4],[3,5,7],[3,5,1]]), [[25,41,33],[42,69,54],[24,39,48]]);
}
test_sqr();


module test_log2() {
    assert_equal(log2(0.125), -3);
    assert_equal(log2(16), 4);
    assert_equal(log2(256), 8);
}
test_log2();


module test_rand_int() {
    nums = rand_int(-100,100,1000,seed=2134);
    assert_equal(len(nums), 1000);
    for (num = nums) {
        assert(num>=-100);
        assert(num<=100);
        assert_equal(num, floor(num));
    }
}
test_rand_int();


module test_gaussian_rands() {
    nums1 = gaussian_rands(0,10,1000,seed=2132);
    nums2 = gaussian_rands(0,10,1000,seed=2130);
    nums3 = gaussian_rands(0,10,1000,seed=2132);
    assert_equal(len(nums1), 1000);
    assert_equal(len(nums2), 1000);
    assert_equal(len(nums3), 1000);
    assert_equal(nums1, nums3);
    assert(nums1!=nums2);
}
test_gaussian_rands();


module test_log_rands() {
    nums1 = log_rands(0,100,10,1000,seed=2189);
    nums2 = log_rands(0,100,10,1000,seed=2310);
    nums3 = log_rands(0,100,10,1000,seed=2189);
    assert_equal(len(nums1), 1000);
    assert_equal(len(nums2), 1000);
    assert_equal(len(nums3), 1000);
    assert_equal(nums1, nums3);
    assert(nums1!=nums2);
}
test_log_rands();


module test_segs() {
    assert_equal(segs(50,$fn=8), 8);
    assert_equal(segs(50,$fa=2,$fs=2), 158);
}
test_segs();


module test_lerp() {
    assert_equal(lerp(-20,20,0), -20);
    assert_equal(lerp(-20,20,0.25), -10);
    assert_equal(lerp(-20,20,0.5), 0);
    assert_equal(lerp(-20,20,0.75), 10);
    assert_equal(lerp(-20,20,1), 20);
    assert_equal(lerp(-20,20,[0,0.25,0.5,0.75,1]), [-20,-10,0,10,20]);
    assert_equal(lerp(-20,20,[0:0.25:1]), [-20,-10,0,10,20]);
    assert_equal(lerp([10,10],[30,-10],0.5), [20,0]);
}
test_lerp();


module test_u_add() {
    assert_equal(u_add(1,2),3);
    assert_equal(u_add(1,-2),-1);
    assert_equal(u_add(-1,2),1);
    assert_equal(u_add(-1,-2),-3);
    assert_equal(u_add(243,-27),216);
    assert_equal(u_add([2,3,4],[8,7,9]),[10,10,13]);
    assert_equal(u_add(undef,27),undef);
    assert_equal(u_add(undef,-27),undef);
    assert_equal(u_add(243,undef),undef);
    assert_equal(u_add(-43,undef),undef);
    assert_equal(u_add(undef,[8,7,9]),undef);
    assert_equal(u_add([2,3,4],undef),undef);
}
test_u_add();


module test_u_sub() {
    assert_equal(u_sub(1,2),-1);
    assert_equal(u_sub(1,-2),3);
    assert_equal(u_sub(-1,2),-3);
    assert_equal(u_sub(-1,-2),1);
    assert_equal(u_sub(243,-27),270);
    assert_equal(u_sub([2,3,4],[8,7,9]),[-6,-4,-5]);
    assert_equal(u_sub(undef,27),undef);
    assert_equal(u_sub(undef,-27),undef);
    assert_equal(u_sub(243,undef),undef);
    assert_equal(u_sub(-43,undef),undef);
    assert_equal(u_sub(undef,[8,7,9]),undef);
    assert_equal(u_sub([2,3,4],undef),undef);
}
test_u_sub();


module test_u_mul() {
    assert_equal(u_mul(3,2),6);
    assert_equal(u_mul(3,-2),-6);
    assert_equal(u_mul(-3,2),-6);
    assert_equal(u_mul(-3,-2),6);
    assert_equal(u_mul(243,-27),-6561);
    assert_equal(u_mul([2,3,4],[8,7,9]),[16,21,36]);
    assert_equal(u_mul(undef,27),undef);
    assert_equal(u_mul(undef,-27),undef);
    assert_equal(u_mul(243,undef),undef);
    assert_equal(u_mul(-43,undef),undef);
    assert_equal(u_mul(undef,[8,7,9]),undef);
    assert_equal(u_mul([2,3,4],undef),undef);
}
test_u_mul();


module test_u_div() {
    assert_equal(u_div(1,2),1/2);
    assert_equal(u_div(1,-2),-1/2);
    assert_equal(u_div(-1,2),-1/2);
    assert_equal(u_div(-1,-2),1/2);
    assert_equal(u_div(243,-27),-9);
    assert_equal(u_div([8,7,9],[2,3,4]),[4,7/3,9/4]);
    assert_equal(u_div(undef,27),undef);
    assert_equal(u_div(undef,-27),undef);
    assert_equal(u_div(243,undef),undef);
    assert_equal(u_div(-43,undef),undef);
    assert_equal(u_div(undef,[8,7,9]),undef);
    assert_equal(u_div([2,3,4],undef),undef);
}
test_u_div();


module test_hypot() {
    assert_approx(hypot(20,30), norm([20,30]));
}
test_hypot();


module test_sinh() {
    assert_approx(sinh(-2), -3.6268604078);
    assert_approx(sinh(-1), -1.1752011936);
    assert_approx(sinh(0), 0);
    assert_approx(sinh(1), 1.1752011936);
    assert_approx(sinh(2), 3.6268604078);
}
test_sinh();


module test_cosh() {
    assert_approx(cosh(-2), 3.7621956911);
    assert_approx(cosh(-1), 1.5430806348);
    assert_approx(cosh(0), 1);
    assert_approx(cosh(1), 1.5430806348);
    assert_approx(cosh(2), 3.7621956911);
}
test_cosh();


module test_tanh() {
    assert_approx(tanh(-2), -0.9640275801);
    assert_approx(tanh(-1), -0.761594156);
    assert_approx(tanh(0), 0);
    assert_approx(tanh(1), 0.761594156);
    assert_approx(tanh(2), 0.9640275801);
}
test_tanh();


module test_asinh() {
    assert_approx(asinh(sinh(-2)), -2);
    assert_approx(asinh(sinh(-1)), -1);
    assert_approx(asinh(sinh(0)), 0);
    assert_approx(asinh(sinh(1)), 1);
    assert_approx(asinh(sinh(2)), 2);
}
test_asinh();


module test_acosh() {
    assert_approx(acosh(cosh(-2)), 2);
    assert_approx(acosh(cosh(-1)), 1);
    assert_approx(acosh(cosh(0)), 0);
    assert_approx(acosh(cosh(1)), 1);
    assert_approx(acosh(cosh(2)), 2);
}
test_acosh();


module test_atanh() {
    assert_approx(atanh(tanh(-2)), -2);
    assert_approx(atanh(tanh(-1)), -1);
    assert_approx(atanh(tanh(0)), 0);
    assert_approx(atanh(tanh(1)), 1);
    assert_approx(atanh(tanh(2)), 2);
}
test_atanh();


module test_sum() {
    assert_equal(sum([]), 0);
    assert_equal(sum([],dflt=undef), undef);
    assert_equal(sum([1,2,3]), 6);
    assert_equal(sum([-2,-1,0,1,2]), 0);
    assert_equal(sum([[1,2,3], [3,4,5], [5,6,7]]), [9,12,15]);
}
test_sum();


module test_cumsum() {
    assert_equal(cumsum([]), []);
    assert_equal(cumsum([1,1,1]), [1,2,3]);
    assert_equal(cumsum([2,2,2]), [2,4,6]);
    assert_equal(cumsum([1,2,3]), [1,3,6]);
    assert_equal(cumsum([-2,-1,0,1,2]), [-2,-3,-3,-2,0]);
    assert_equal(cumsum([[1,2,3], [3,4,5], [5,6,7]]), [[1,2,3],[4,6,8],[9,12,15]]);
}
test_cumsum();


module test_sum_of_sines() {
    assert_equal(sum_of_sines(0, [[3,4,0],[2,2,0]]), 0);
    assert_equal(sum_of_sines(45, [[3,4,0],[2,2,0]]), 2);
    assert_equal(sum_of_sines(90, [[3,4,0],[2,2,0]]), 0);
    assert_equal(sum_of_sines(135, [[3,4,0],[2,2,0]]), -2);
    assert_equal(sum_of_sines(180, [[3,4,0],[2,2,0]]), 0);
}
test_sum_of_sines();


module test_deltas() {
    assert_equal(deltas([2,5,9,17]), [3,4,8]);
    assert_equal(deltas([2,5,9,17],wrap=true), [3,4,8,-15]);
    assert_equal(deltas([[1,2,3], [3,6,8], [4,8,11]]), [[2,4,5], [1,2,3]]);
    assert_equal(deltas([[1,2,3], [3,6,8], [4,8,11]],wrap=true), [[2,4,5], [1,2,3], [-3,-6,-8]]);
}
test_deltas();


module test_product() {
    assert_equal(product([2,3,4]), 24);
    assert_equal(product([[1,2,3], [3,4,5], [5,6,7]]), [15, 48, 105]);
    m1 = [[2,3,4],[4,5,6],[6,7,8]];
    m2 = [[4,1,2],[3,7,2],[8,7,4]];
    m3 = [[3,7,8],[9,2,4],[5,8,3]];
    assert_equal(product([m1,m2,m3]), m1*m2*m3);
}
test_product();


module test_mean() {
    assert_equal(mean([2,3,4]), 3);
    assert_equal(mean([[1,2,3], [3,4,5], [5,6,7]]), [3,4,5]);
}
test_mean();

/*
module test_median() {
    assert_equal(median([2,3,7]), 4.5);
    assert_equal(median([[1,2,3], [3,4,5], [8,9,10]]), [4.5,5.5,6.5]);
}
test_median();
*/


module test_convolve() {
    assert_equal(convolve([],[1,2,1]), []);
    assert_equal(convolve([1,1],[]), []);
    assert_equal(convolve([1,1],[1,2,1]), [1,3,3,1]);
    assert_equal(convolve([1,2,3],[1,2,1]), [1,4,8,8,3]);
    assert_equal(convolve([1,2,3],[[1],[2],[1]]),  [[1], [4], [8], [8], [3]]);
    assert_equal(convolve([[1],[2],[3]],[[1],[2],[1]]), [1,4,8,8,3]);
    assert_equal(convolve([[1,0],[2,1],[3,2]],[[1,0],[2,1],[1,2]]), [1,4,9,12,7]);
    assert_equal(convolve([1,2,3],[[1,0],[2,1],[1,2]]), [[1,0],[4,1],[8,4],[8,7],[3,6]]);
}
test_convolve();



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


// Logic


module test_compare_vals() {
    assert(compare_vals(-10,0) < 0);
    assert(compare_vals(10,0) > 0);
    assert(compare_vals(10,10) == 0);

    assert(compare_vals("abc","abcd") < 0);
    assert(compare_vals("abcd","abc") > 0);
    assert(compare_vals("abcd","abcd") == 0);

    assert(compare_vals(false,false) == 0);
    assert(compare_vals(true,false) > 0);
    assert(compare_vals(false,true) < 0);
    assert(compare_vals(true,true) == 0);

    assert(compare_vals([2,3,4], [2,3,4,5]) < 0);
    assert(compare_vals([2,3,4,5], [2,3,4,5]) == 0);
    assert(compare_vals([2,3,4,5], [2,3,4]) > 0);
    assert(compare_vals([2,3,4,5], [2,3,5,5]) < 0);
    assert(compare_vals([[2,3,4,5]], [[2,3,5,5]]) < 0);

    assert(compare_vals([[2,3,4],[3,4,5]], [[2,3,4], [3,4,5]]) == 0);
    assert(compare_vals([[2,3,4],[3,4,5]], [[2,3,4,5], [3,4,5]]) < 0);
    assert(compare_vals([[2,3,4],[3,4,5]], [[2,3,4], [3,4,5,6]]) < 0);
    assert(compare_vals([[2,3,4,5],[3,4,5]], [[2,3,4], [3,4,5]]) > 0);
    assert(compare_vals([[2,3,4],[3,4,5,6]], [[2,3,4], [3,4,5]]) > 0);
    assert(compare_vals([[2,3,4],[3,5,5]], [[2,3,4], [3,4,5]]) > 0);
    assert(compare_vals([[2,3,4],[3,4,5]], [[2,3,4], [3,5,5]]) < 0);

    assert(compare_vals(undef, undef) == 0);
    assert(compare_vals(undef, true) < 0);
    assert(compare_vals(undef, 0) < 0);
    assert(compare_vals(undef, "foo") < 0);
    assert(compare_vals(undef, [2,3,4]) < 0);
    assert(compare_vals(undef, [0:3]) < 0);

    assert(compare_vals(true, undef) > 0);
    assert(compare_vals(true, true) == 0);
    assert(compare_vals(true, 0) < 0);
    assert(compare_vals(true, "foo") < 0);
    assert(compare_vals(true, [2,3,4]) < 0);
    assert(compare_vals(true, [0:3]) < 0);

    assert(compare_vals(0, undef) > 0);
    assert(compare_vals(0, true) > 0);
    assert(compare_vals(0, 0) == 0);
    assert(compare_vals(0, "foo") < 0);
    assert(compare_vals(0, [2,3,4]) < 0);
    assert(compare_vals(0, [0:3]) < 0);

    assert(compare_vals(1, undef) > 0);
    assert(compare_vals(1, true) > 0);
    assert(compare_vals(1, 1) == 0);
    assert(compare_vals(1, "foo") < 0);
    assert(compare_vals(1, [2,3,4]) < 0);
    assert(compare_vals(1, [0:3]) < 0);

    assert(compare_vals("foo", undef) > 0);
    assert(compare_vals("foo", true) > 0);
    assert(compare_vals("foo", 1) > 0);
    assert(compare_vals("foo", "foo") == 0);
    assert(compare_vals("foo", [2,3,4]) < 0);
    assert(compare_vals("foo", [0:3]) < 0);

    assert(compare_vals([2,3,4], undef) > 0);
    assert(compare_vals([2,3,4], true) > 0);
    assert(compare_vals([2,3,4], 1) > 0);
    assert(compare_vals([2,3,4], "foo") > 0);
    assert(compare_vals([2,3,4], [2,3,4]) == 0);
    assert(compare_vals([2,3,4], [0:3]) < 0);

    assert(compare_vals([0:3], undef) > 0);
    assert(compare_vals([0:3], true) > 0);
    assert(compare_vals([0:3], 1) > 0);
    assert(compare_vals([0:3], "foo") > 0);
    assert(compare_vals([0:3], [2,3,4]) > 0);
    assert(compare_vals([0:3], [0:3]) == 0);
}
test_compare_vals();


module test_compare_lists() {
    assert(compare_lists([2,3,4], [2,3,4,5]) < 0);
    assert(compare_lists([2,3,4,5], [2,3,4,5]) == 0);
    assert(compare_lists([2,3,4,5], [2,3,4]) > 0);
    assert(compare_lists([2,3,4,5], [2,3,5,5]) < 0);

    assert(compare_lists([[2,3,4],[3,4,5]], [[2,3,4], [3,4,5]]) == 0);
    assert(compare_lists([[2,3,4],[3,4,5]], [[2,3,4,5], [3,4,5]]) < 0);
    assert(compare_lists([[2,3,4],[3,4,5]], [[2,3,4], [3,4,5,6]]) < 0);
    assert(compare_lists([[2,3,4,5],[3,4,5]], [[2,3,4], [3,4,5]]) > 0);
    assert(compare_lists([[2,3,4],[3,4,5,6]], [[2,3,4], [3,4,5]]) > 0);
    assert(compare_lists([[2,3,4],[3,5,5]], [[2,3,4], [3,4,5]]) > 0);
    assert(compare_lists([[2,3,4],[3,4,5]], [[2,3,4], [3,5,5]]) < 0);

    assert(compare_lists("cat", "bat") > 0);
    assert(compare_lists(["cat"], ["bat"]) > 0);
}
test_compare_lists();


module test_any() {
    assert_equal(any([0,false,undef]), false);
    assert_equal(any([1,false,undef]), true);
    assert_equal(any([1,5,true]), true);
    assert_equal(any([[0,0], [0,0]]), true);
    assert_equal(any([[0,0], [1,0]]), true);
    assert_equal(any([[false,false],[[false,[false],[[[true]]]],false],[false,false]]), true);
    assert_equal(any([[false,false],[[false,[false],[[[false]]]],false],[false,false]]), true);
    assert_equal(any([]), false);
    assert_equal(any([1,3,5,7,9], function (a) a%2==0),false);
    assert_equal(any([1,3,6,7,9], function (a) a%2==0),true);
    assert_equal(any([1,3,5,7,9], function (a) a%2!=0),true);
}
test_any();


module test_all() {
    assert_equal(all([0,false,undef]), false);
    assert_equal(all([1,false,undef]), false);
    assert_equal(all([1,5,true]), true);
    assert_equal(all([[0,0], [0,0]]), true);
    assert_equal(all([[0,0], [1,0]]), true);
    assert_equal(all([[1,1], [1,1]]), true);
    assert_equal(all([[true,true],[[true,[true],[[[true]]]],true],[true,true]]), true);
    assert_equal(all([[true,true],[[true,[true],[[[false]]]],true],[true,true]]), true);
    assert_equal(all([]), true);
    assert_equal(all([1,3,5,7,9], function (a) a%2==0),false);
    assert_equal(all([1,3,6,8,9], function (a) a%2==0),false);
    assert_equal(all([1,3,5,7,9], function (a) a%2!=0),true);
}
test_all();


module test_count_true() {
    assert_equal(count_true([0,false,undef]), 0);
    assert_equal(count_true([1,false,undef]), 1);
    assert_equal(count_true([1,5,false]), 2);
    assert_equal(count_true([1,5,true]), 3);
    assert_equal(count_true([[0,0], [0,0]]), 2);
    assert_equal(count_true([[0,0], [1,0]]), 2);
    assert_equal(count_true([[1,1], [1,1]]), 2);
    assert_equal(count_true([1,1,1,1,1], nmax=3), 3);
    assert_equal(count_true([1,3,5,7,9], function (a) a%2==0),0);
    assert_equal(count_true([1,3,6,8,9], function (a) a%2==0),2);
    assert_equal(count_true([1,3,5,7,9], function (a) a%2!=0),5);
}
test_count_true();


module test_factorial() {
    assert_equal(factorial(0), 1);
    assert_equal(factorial(1), 1);
    assert_equal(factorial(2), 2);
    assert_equal(factorial(3), 6);
    assert_equal(factorial(4), 24);
    assert_equal(factorial(5), 120);
    assert_equal(factorial(6), 720);
    assert_equal(factorial(7), 5040);
    assert_equal(factorial(8), 40320);
    assert_equal(factorial(25,21), 303600);
    assert_equal(factorial(25,25), 1);
}
test_factorial();


module test_binomial() {
    assert_equal(binomial(1), [1,1]);
    assert_equal(binomial(2), [1,2,1]);
    assert_equal(binomial(3), [1,3,3,1]);
    assert_equal(binomial(5), [1,5,10,10,5,1]);
}
test_binomial();


module test_binomial_coefficient() {
    assert_equal(binomial_coefficient(2,1), 2);
    assert_equal(binomial_coefficient(3,2), 3);
    assert_equal(binomial_coefficient(4,2), 6);
    assert_equal(binomial_coefficient(10,7), 120);
    assert_equal(binomial_coefficient(10,7), binomial(10)[7]);
    assert_equal(binomial_coefficient(15,4), binomial(15)[4]);
}
test_binomial_coefficient();


module test_gcd() {
    assert_equal(gcd(15,25), 5);
    assert_equal(gcd(15,27), 3);
    assert_equal(gcd(270,405), 135);
    assert_equal(gcd(39, 101),1);
    assert_equal(gcd(15,-25), 5);
    assert_equal(gcd(-15,25), 5);
    assert_equal(gcd(5,0), 5);
    assert_equal(gcd(0,5), 5);
}
test_gcd();


module test_lcm() {
    assert_equal(lcm(15,25), 75);
    assert_equal(lcm(15,27), 135);
    assert_equal(lcm(270,405), 810);
    assert_equal(lcm([3,5,15,25,35]),525);
}
test_lcm();



module test_complex(){
    assert_equal( complex(ident(4)), c_ident(4));
    assert_equal( complex(3), [3,0]);
    assert_equal( complex([1,2]), [[1,0],[2,0]]);
    assert_equal( complex([[1,2],[3,4]]), [[ [1,0],[2,0] ], [ [3,0],[4,0]]]);
}
test_complex();

module test_c_mul() {
    assert_equal(c_mul([4,5],[9,-4]), [56,29]);
    assert_equal(c_mul([-7,2],[24,3]), [-174, 27]);
    assert_equal(c_mul([3,4], [[3,-7], [4,9], [4,8]]), [[37,-9],[-24,43], [-20,40]]);
    assert_equal(c_mul([[3,-7], [4,9], [4,8]], [[1,1],[3,4],[-3,4]]), [-58,31]);
    M = [
           [ [3,4], [9,-1], [4,3] ],
           [ [2,9], [4,9], [3,-1] ]
        ];
    assert_equal(c_mul(M, [ [3,4], [4,4],[5,5]]), [[38,91], [-30, 97]]);
    assert_equal(c_mul([[4,4],[9,1]], M), [[5,111],[67,117], [32,22]]);
    assert_equal(c_mul(M,transpose(M)), [  [[80,30], [30, 117]], [[30,117], [-134, 102]]]);
    assert_equal(c_mul(transpose(M),M), [  [[-84,60],[-42,87],[15,50]], [[-42,87],[15,54],[60,46]], [[15,50],[60,46],[15,18]]]);
}
test_c_mul();


module test_c_div() {
    assert_equal(c_div([56,29],[9,-4]), [4,5]);
    assert_equal(c_div([-174,27],[-7,2]), [24,3]);
}    
test_c_div();

module test_c_conj(){
    assert_equal(c_conj([3,4]), [3,-4]);
    assert_equal(c_conj(           [ [2,9], [4,9], [3,-1] ]),            [ [2,-9], [4,-9], [3,1] ]);
    M = [
           [ [3,4], [9,-1], [4,3] ],
           [ [2,9], [4,9], [3,-1] ]
        ];
    Mc = [
           [ [3,-4], [9,1], [4,-3] ],
           [ [2,-9], [4,-9], [3,1] ]
        ];
    assert_equal(c_conj(M), Mc);
}
test_c_conj();

module test_c_real(){
    M = [
           [ [3,4], [9,-1], [4,3] ],
           [ [2,9], [4,9], [3,-1] ]
        ];
    assert_equal(c_real(M), [[3,9,4],[2,4,3]]);
    assert_equal(c_real(           [ [3,4], [9,-1], [4,3] ]), [3,9,4]);
    assert_equal(c_real([3,4]),3);
}
test_c_real();


module test_c_imag(){
    M = [
           [ [3,4], [9,-1], [4,3] ],
           [ [2,9], [4,9], [3,-1] ]
        ];
    assert_equal(c_imag(M), [[4,-1,3],[9,9,-1]]);
    assert_equal(c_imag(           [ [3,4], [9,-1], [4,3] ]), [4,-1,3]);
    assert_equal(c_imag([3,4]),4);
}
test_c_imag();


module test_c_ident(){
  assert_equal(c_ident(3), [[[1, 0], [0, 0], [0, 0]], [[0, 0], [1, 0], [0, 0]], [[0, 0], [0, 0], [1, 0]]]);
}
test_c_ident();

module test_c_norm(){
  assert_equal(c_norm([3,4]), 5);
  assert_approx(c_norm([[3,4],[5,6]]), 9.273618495495704);
}
test_c_norm();

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
  assert_approx(linear_solve(subindex(M,[0:2]), [2,4,4,4]),
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


module test_cumprod(){
  assert_equal(cumprod([1,2,3,4]), [1,2,6,24]);
  assert_equal(cumprod([4]), [4]);
  assert_equal(cumprod([]),[]);
  assert_equal(cumprod([[2,3],[4,5],[6,7]]), [[2,3],[8,15],[48,105]]);
  assert_equal(cumprod([[5,6,7]]),[[5,6,7]]);
  assert_equal(cumprod([
                        [[1,2],[3,4]],
                        [[-4,5],[6,4]],
                        [[9,-3],[4,3]]
                       ]),
                       [
                        [[1,2],[3,4]],
                        [[8,13],[12,31]],
                        [[124,15],[232,57]]
                       ]);
  assert_equal(cumprod([[[1,2],[3,4]]]), [[[1,2],[3,4]]]);
}
test_cumprod();
                         


module test_outer_product(){
  assert_equal(outer_product([1,2,3],[4,5,6]), [[4,5,6],[8,10,12],[12,15,18]]);
  assert_equal(outer_product([1,2],[4,5,6]), [[4,5,6],[8,10,12]]);
  assert_equal(outer_product([9],[7]), [[63]]);
}
test_outer_product();


module test_deriv(){
  pent = [for(x=[0:70:359]) [cos(x), sin(x)]];
  assert_approx(deriv(pent,closed=true), 
        [[-0.321393804843,0.556670399226],
         [-0.883022221559,0.321393804843],
         [-0.604022773555,-0.719846310393],
         [0.469846310393,-0.813797681349],
         [0.925416578398,0.163175911167],
         [0.413175911167,0.492403876506]]);
  assert_approx(deriv(pent,closed=true,h=2), 
     0.5*[[-0.321393804843,0.556670399226],
         [-0.883022221559,0.321393804843],
         [-0.604022773555,-0.719846310393],
         [0.469846310393,-0.813797681349],
         [0.925416578398,0.163175911167],
         [0.413175911167,0.492403876506]]);
  assert_approx(deriv(pent,closed=false),
        [[-0.432937491789,1.55799143673],
         [-0.883022221559,0.321393804843],
         [-0.604022773555,-0.719846310393],
         [0.469846310393,-0.813797681349],
         [0.925416578398,0.163175911167],
         [0.696902572292,1.45914323952]]);
  spent = yscale(8,p=pent);
  lens = path_segment_lengths(spent,closed=true);
  assert_approx(deriv(spent, closed=true, h=lens),
         [[-0.0381285841663,0.998065839726],
          [-0.254979378104,0.0449763331253],
          [-0.216850793938,-0.953089506601],
          [0.123993253223,-0.982919228715],
          [0.191478335034,0.0131898128456],
          [0.0674850818111,0.996109041561]]);
  assert_approx(deriv(spent, closed=false, h=select(lens,0,-2)),
         [[-0.0871925973657,0.996191473044],
          [-0.254979378104,0.0449763331253],
          [-0.216850793938,-0.953089506601],
          [0.123993253223,-0.982919228715],
          [0.191478335034,0.0131898128456],
          [0.124034734589,0.992277876714]]);
}
test_deriv();


module test_deriv2(){
    oct = [for(x=[0:45:359]) [cos(x), sin(x)]];
    assert_approx(deriv2(oct),
           [[-0.828427124746,0.0719095841794],[-0.414213562373,-0.414213562373],[0,-0.585786437627],
            [0.414213562373,-0.414213562373],[0.585786437627,0],[0.414213562373,0.414213562373],
            [0,0.585786437627],[-0.636634192232,0.534938683021]]);
    assert_approx(deriv2(oct,closed=false),
           [[-0.828427124746,0.0719095841794],[-0.414213562373,-0.414213562373],[0,-0.585786437627],
            [0.414213562373,-0.414213562373],[0.585786437627,0],[0.414213562373,0.414213562373],
            [0,0.585786437627],[-0.636634192232,0.534938683021]]);
    assert_approx(deriv2(oct,closed=true),
           [[-0.585786437627,0],[-0.414213562373,-0.414213562373],[0,-0.585786437627],
            [0.414213562373,-0.414213562373],[0.585786437627,0],[0.414213562373,0.414213562373],
            [0,0.585786437627],[-0.414213562373,0.414213562373]]);
    assert_approx(deriv2(oct,closed=false,h=2),
         0.25*[[-0.828427124746,0.0719095841794],[-0.414213562373,-0.414213562373],[0,-0.585786437627],
            [0.414213562373,-0.414213562373],[0.585786437627,0],[0.414213562373,0.414213562373],
            [0,0.585786437627],[-0.636634192232,0.534938683021]]);
    assert_approx(deriv2(oct,closed=true,h=2),
         0.25* [[-0.585786437627,0],[-0.414213562373,-0.414213562373],[0,-0.585786437627],
            [0.414213562373,-0.414213562373],[0.585786437627,0],[0.414213562373,0.414213562373],
            [0,0.585786437627],[-0.414213562373,0.414213562373]]);
}
test_deriv2();


module test_deriv3(){
    oct = [for(x=[0:45:359]) [cos(x), sin(x)]];
    assert_approx(deriv3(oct),
           [[0.414213562373,-0.686291501015],[0.414213562373,-0.343145750508],[0.414213562373,0],
            [0.292893218813,0.292893218813],[0,0.414213562373],[-0.292893218813,0.292893218813],
            [-0.535533905933,0.0502525316942],[-0.778174593052,-0.192388155425]]);
    assert_approx(deriv3(oct,closed=false),
           [[0.414213562373,-0.686291501015],[0.414213562373,-0.343145750508],[0.414213562373,0],
            [0.292893218813,0.292893218813],[0,0.414213562373],[-0.292893218813,0.292893218813],
            [-0.535533905933,0.0502525316942],[-0.778174593052,-0.192388155425]]);
    assert_approx(deriv3(oct,closed=false,h=2),
           [[0.414213562373,-0.686291501015],[0.414213562373,-0.343145750508],[0.414213562373,0],
            [0.292893218813,0.292893218813],[0,0.414213562373],[-0.292893218813,0.292893218813],
            [-0.535533905933,0.0502525316942],[-0.778174593052,-0.192388155425]]/8);
    assert_approx(deriv3(oct,closed=true),
           [[0,-0.414213562373],[0.292893218813,-0.292893218813],[0.414213562373,0],[0.292893218813,0.292893218813],
            [0,0.414213562373],[-0.292893218813,0.292893218813],[-0.414213562373,0],[-0.292893218813,-0.292893218813]]);
    assert_approx(deriv3(oct,closed=true,h=2),
           [[0,-0.414213562373],[0.292893218813,-0.292893218813],[0.414213562373,0],[0.292893218813,0.292893218813],
            [0,0.414213562373],[-0.292893218813,0.292893218813],[-0.414213562373,0],[-0.292893218813,-0.292893218813]]/8);
}
test_deriv3();
  


module test_polynomial(){
  assert_equal(polynomial([0],12),0);
  assert_equal(polynomial([0],[12,4]),[0,0]);
//  assert_equal(polynomial([],12),0);
//  assert_equal(polynomial([],[12,4]),[0,0]);
  assert_equal(polynomial([1,2,3,4],3),58);
  assert_equal(polynomial([1,2,3,4],[3,-1]),[47,-41]);
  assert_equal(polynomial([0,0,2],4),2);
}
test_polynomial();


module test_poly_roots(){
   // Fifth roots of unity
   assert_approx(
        poly_roots([1,0,0,0,0,-1]),
        [[1,0],[0.309016994375,0.951056516295],[-0.809016994375,0.587785252292],
         [-0.809016994375,-0.587785252292],[0.309016994375,-0.951056516295]]);
   assert_approx(poly_roots(poly_mult([[1,-2,5],[12,-24,24],[-2, -12, -20],[1,-10,50]])),
               [[1, 1], [5, 5], [1, 2], [-3, 1], [-3, -1], [1, -1], [1, -2], [5, -5]]);
   assert_approx(poly_roots([.124,.231,.942, -.334]),
                 [[0.3242874219074053,0],[-1.093595323856930,2.666477428660098], [-1.093595323856930,-2.666477428660098]]);
}
test_poly_roots();

module test_real_roots(){
   // Wilkinson polynomial is a nasty test:
   assert_approx(
       sort(real_roots(poly_mult([[1,-1],[1,-2],[1,-3],[1,-4],[1,-5],[1,-6],[1,-7],[1,-8],[1,-9],[1,-10]]))),
       count(10,1));
   assert_equal(real_roots([3]), []);
   assert_equal(real_roots(poly_mult([[1,-2,5],[12,-24,24],[-2, -12, -20],[1,-10,50]])),[]);
   assert_equal(real_roots(poly_mult([[1,-2,5],[12,-24,24],[-2, -12, -20],[1,-10,50],[1,0,0]])),[0,0]);
   assert_approx(real_roots(poly_mult([[1,-2,5],[12,-24,24],[-2, -12, -20],[1,-10,50],[1,4]])),[-4]);
   assert(approx(real_roots([1,-10,25]),[5,5],eps=5e-6));
   assert_approx(real_roots([4,-3]), [0.75]);
   assert_approx(real_roots([0,0,0,4,-3]), [0.75]);
}
test_real_roots();



module test_quadratic_roots(){
    assert_approx(quadratic_roots([1,4,4]),[[-2,0],[-2,0]]);
    assert_approx(quadratic_roots([1,4,4],real=true),[-2,-2]);
    assert_approx(quadratic_roots([1,-5,6],real=true), [2,3]);
    assert_approx(quadratic_roots([1,-5,6]), [[2,0],[3,0]]);
}
test_quadratic_roots();


module test_null_space(){
    assert_equal(null_space([[3,2,1],[3,6,3],[3,9,-3]]),[]);

    function nullcheck(A,dim) =
      let(v=null_space(A))
        len(v)==dim && all_zero(A*transpose(v),eps=1e-12);
    
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
    && list_decreasing([for(i=[0:1:min(len(qr[1]),len(qr[1][0]))-1]) abs(qr[1][i][i])]);

  
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


module test_poly_mult(){
  assert_equal(poly_mult([3,2,1],[4,5,6,7]),[12,23,32,38,20,7]);
  assert_equal(poly_mult([[1,2],[3,4],[5,6]]), [15,68,100,48]);
  assert_equal(poly_mult([3,2,1],[0]),[0]);
  assert_equal(poly_mult([[1,2],[0],[5,6]]), [0]);
  assert_equal(poly_mult([[3,4,5],[0,0,0]]), [0]);
  assert_equal(poly_mult([[0],[0,0,0]]),[0]);
}
test_poly_mult();


module test_poly_div(){
  assert_equal(poly_div(poly_mult([4,3,3,2],[2,1,3]), [2,1,3]),[[4,3,3,2],[0]]);
  assert_equal(poly_div([1,2,3,4],[1,2,3,4,5]), [[], [1,2,3,4]]);
  assert_equal(poly_div(poly_add(poly_mult([1,2,3,4],[2,0,2]), [1,1,2]), [1,2,3,4]), [[2,0,2],[1,1,2]]);
  assert_equal(poly_div([1,2,3,4], [1,-3]), [[1,5,18],[58]]);
  assert_equal(poly_div([0], [1,-3]), [[0],[0]]);
}
test_poly_div();


module test_poly_add(){
  assert_equal(poly_add([2,3,4],[3,4,5,6]),[3,6,8,10]);
  assert_equal(poly_add([1,2,3,4],[-1,-2,3,4]), [6,8]);
  assert_equal(poly_add([1,2,3],-[1,2,3]),[0]);
//  assert_equal(poly_add([1,2,3],-[1,2,3]),[]);
}
test_poly_add();


module test_root_find(){
  flist = [
      function(x) x*x*x-2*x-5,
      function(x) 1-1/x/x,
      function(x) pow(x-3,3),
      function(x) pow(x-2,5),
      function(x) (let(xi=0.61489) -3062*(1-xi)*exp(-x)/(xi+(1-xi)*exp(-x)) -1013 + 1628/x),
      function(x) exp(x)-2-.01/x/x + .000002/x/x/x,
  ];
  fint=[
        [0,4],
        [1e-4, 4],
        [0,6],
        [0,4],
        [1e-4,5],
        [-1,4]
  ];
  answers = [2.094551481542328,
             1,
             3,
             2,
             1.037536033287040,
             0.7032048403631350
  ];
  
  roots = [for(i=idx(flist)) root_find(flist[i], fint[i][0], fint[i][1])];
  assert_approx(roots, answers, 1e-10);
}
test_root_find();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
