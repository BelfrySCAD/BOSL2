include <BOSL2/std.scad>

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
    assert(is_matrix([[2,3,4],[5,6,7],[8,9,10]],square=true));
    assert(is_matrix([[2,3,4],[5,6,7],[8,9,10]],square=false));
    assert(is_matrix([[2,3],[5,6],[8,9]],m=3,n=2));
    assert(is_matrix([[2,3,4],[5,6,7]],m=2,n=3));
    assert(!is_matrix([[2,3,4],[5,6,7]],m=2,n=3,square=true));
    assert(is_matrix([[2,3,4],[5,6,7],[8,9,10]],square=false));
    assert(!is_matrix([[2,3],[5,6],[8,9]],m=2,n=3));
    assert(!is_matrix([[2,3,4],[5,6,7]],m=3,n=2));
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
}
test_approx();


module test_min_index() {
    vals = rands(-100,100,100);
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
    vals = rands(-100,100,100);
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


module test_modrange() {
    assert_equal(modrange(-5,5,3), [1,2]);
    assert_equal(modrange(-1,4,3), [2,0,1]);
    assert_equal(modrange(1,8,10,step=2), [1,3,5,7]);
    assert_equal(modrange(5,12,10,step=2), [5,7,9,1]);
}
test_modrange();


module test_sqr() {
    assert_equal(sqr(-3), 9);
    assert_equal(sqr(0), 0);
    assert_equal(sqr(1), 1);
    assert_equal(sqr(2), 4);
    assert_equal(sqr(2.5), 6.25);
    assert_equal(sqr(3), 9);
    assert_equal(sqr(16), 256);
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


module test_sum_of_squares() {
    assert_equal(sum_of_squares([1,2,3]), 14);
    assert_equal(sum_of_squares([1,2,4]), 21);
    assert_equal(sum_of_squares([-3,-2,-1]), 14);
}
test_sum_of_squares();


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
    assert_equal(deltas([[1,2,3], [3,6,8], [4,8,11]]), [[2,4,5], [1,2,3]]);
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


module test_median() {
    assert_equal(median([2,3,7]), 4.5);
    assert_equal(median([[1,2,3], [3,4,5], [8,9,10]]), [4.5,5.5,6.5]);
}
test_median();


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
    assert_equal(any([[0,0], [0,0]]), false);
    assert_equal(any([[0,0], [1,0]]), true);
}
test_any();


module test_all() {
    assert_equal(all([0,false,undef]), false);
    assert_equal(all([1,false,undef]), false);
    assert_equal(all([1,5,true]), true);
    assert_equal(all([[0,0], [0,0]]), false);
    assert_equal(all([[0,0], [1,0]]), false);
    assert_equal(all([[1,1], [1,1]]), true);
}
test_all();


module test_count_true() {
    assert_equal(count_true([0,false,undef]), 0);
    assert_equal(count_true([1,false,undef]), 1);
    assert_equal(count_true([1,5,false]), 2);
    assert_equal(count_true([1,5,true]), 3);
    assert_equal(count_true([[0,0], [0,0]]), 0);
    assert_equal(count_true([[0,0], [1,0]]), 1);
    assert_equal(count_true([[1,1], [1,1]]), 4);
    assert_equal(count_true([[1,1], [1,1]], nmax=3), 3);
}
test_count_true();


module test_factorial() {
    assert_equal(factorial(1), 1);
    assert_equal(factorial(2), 2);
    assert_equal(factorial(3), 6);
    assert_equal(factorial(4), 24);
    assert_equal(factorial(5), 120);
    assert_equal(factorial(6), 720);
    assert_equal(factorial(7), 5040);
    assert_equal(factorial(8), 40320);
}
test_factorial();


module test_gcd() {
    assert_equal(gcd(15,25), 5);
    assert_equal(gcd(15,27), 3);
    assert_equal(gcd(270,405), 135);
}
test_gcd();


module test_lcm() {
    assert_equal(lcm(15,25), 75);
    assert_equal(lcm(15,27), 135);
    assert_equal(lcm(270,405), 810);
}
test_lcm();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
