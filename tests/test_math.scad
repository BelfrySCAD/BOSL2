include <BOSL2/std.scad>

// Simple Calculations

module test_quant() {
	assert(quant(-4,3) == -3);
	assert(quant(-3,3) == -3);
	assert(quant(-2,3) == -3);
	assert(quant(-1,3) == 0);
	assert(quant(0,3) == 0);
	assert(quant(1,3) == 0);
	assert(quant(2,3) == 3);
	assert(quant(3,3) == 3);
	assert(quant(4,3) == 3);
	assert(quant(7,3) == 6);
}
test_quant();


module test_quantdn() {
	assert(quantdn(-4,3) == -6);
	assert(quantdn(-3,3) == -3);
	assert(quantdn(-2,3) == -3);
	assert(quantdn(-1,3) == -3);
	assert(quantdn(0,3) == 0);
	assert(quantdn(1,3) == 0);
	assert(quantdn(2,3) == 0);
	assert(quantdn(3,3) == 3);
	assert(quantdn(4,3) == 3);
	assert(quantdn(7,3) == 6);
}
test_quantdn();


module test_quantup() {
	assert(quantup(-4,3) == -3);
	assert(quantup(-3,3) == -3);
	assert(quantup(-2,3) == 0);
	assert(quantup(-1,3) == 0);
	assert(quantup(0,3) == 0);
	assert(quantup(1,3) == 3);
	assert(quantup(2,3) == 3);
	assert(quantup(3,3) == 3);
	assert(quantup(4,3) == 6);
	assert(quantup(7,3) == 9);
}
test_quantup();


module test_constrain() {
	assert(constrain(-2,-1,1) == -1);
	assert(constrain(-1.75,-1,1) == -1);
	assert(constrain(-1,-1,1) == -1);
	assert(constrain(-0.75,-1,1) == -0.75);
	assert(constrain(0,-1,1) == 0);
	assert(constrain(0.75,-1,1) == 0.75);
	assert(constrain(1,-1,1) == 1);
	assert(constrain(1.75,-1,1) == 1);
	assert(constrain(2,-1,1) == 1);
}
test_constrain();


module test_approx() {
	assert(approx(PI, 3.141592653589793236) == true);
	assert(approx(PI, 3.1415926) == false);
	assert(approx(PI, 3.1415926, eps=1e-6) == true);
	assert(approx(-PI, -3.141592653589793236) == true);
	assert(approx(-PI, -3.1415926) == false);
	assert(approx(-PI, -3.1415926, eps=1e-6) == true);
	assert(approx(1/3, 0.3333333333) == true);
	assert(approx(-1/3, -0.3333333333) == true);
	assert(approx(10*[cos(30),sin(30)], 10*[sqrt(3)/2, 1/2]) == true);
}
test_approx();


module test_min_index() {
	vals = rands(-100,100,100);
	minval = min(vals);
	minidx = min_index(vals);
	assert(vals[minidx] == minval);
	assert(min_index([3,4,5,6]) == 0);
	assert(min_index([4,3,5,6]) == 1);
	assert(min_index([4,5,3,6]) == 2);
	assert(min_index([4,5,6,3]) == 3);
	assert(min_index([6,5,4,3]) == 3);
	assert(min_index([6,3,4,5]) == 1);
	assert(min_index([-56,72,-874,5]) == 2);
}
test_min_index();


module test_max_index() {
	vals = rands(-100,100,100);
	maxval = max(vals);
	maxidx = max_index(vals);
	assert(vals[maxidx] == maxval);
	assert(max_index([3,4,5,6]) == 3);
	assert(max_index([3,4,6,5]) == 2);
	assert(max_index([3,6,4,5]) == 1);
	assert(max_index([6,3,4,5]) == 0);
	assert(max_index([5,6,4,3]) == 1);
	assert(max_index([-56,72,-874,5]) == 1);
}
test_max_index();


module test_posmod() {
	assert(posmod(-5,3) == 1);
	assert(posmod(-4,3) == 2);
	assert(posmod(-3,3) == 0);
	assert(posmod(-2,3) == 1);
	assert(posmod(-1,3) == 2);
	assert(posmod(0,3) == 0);
	assert(posmod(1,3) == 1);
	assert(posmod(2,3) == 2);
	assert(posmod(3,3) == 0);
}
test_posmod();


module test_modrange() {
	assert(modrange(-5,5,3) == [1,2]);
	assert(modrange(-1,4,3) == [2,0,1]);
	assert(modrange(1,8,10,step=2) == [1,3,5,7]);
	assert(modrange(5,12,10,step=2) == [5,7,9,1]);
}
test_modrange();


module test_sqr() {
	assert(sqr(-3) == 9);
	assert(sqr(0) == 0);
	assert(sqr(1) == 1);
	assert(sqr(2) == 4);
	assert(sqr(3) == 9);
	assert(sqr(16) == 256);
}
test_sqr();


// TODO: Tests for gaussian_rand()
// TODO: Tests for log_rand()

module test_segs() {
	assert(segs(50,$fn=8) == 8);
	assert(segs(50,$fa=2,$fs=2) == 158);
}
test_segs();


module test_lerp() {
	assert(lerp(-20,20,0) == -20);
	assert(lerp(-20,20,0.25) == -10);
	assert(lerp(-20,20,0.5) == 0);
	assert(lerp(-20,20,0.75) == 10);
	assert(lerp(-20,20,1) == 20);
	assert(lerp([10,10],[30,-10],0.5) == [20,0]);
}
test_lerp();


module test_hypot() {
	assert(hypot(20,30) == norm([20,30]));
}
test_hypot();


module test_sinh() {
	assert(abs(sinh(-2)+3.6268604078) < EPSILON);
	assert(abs(sinh(-1)+1.1752011936) < EPSILON);
	assert(abs(sinh(0)) < EPSILON);
	assert(abs(sinh(1)-1.1752011936) < EPSILON);
	assert(abs(sinh(2)-3.6268604078) < EPSILON);
}
test_sinh();


module test_cosh() {
	assert(abs(cosh(-2)-3.7621956911) < EPSILON);
	assert(abs(cosh(-1)-1.5430806348) < EPSILON);
	assert(abs(cosh(0)-1) < EPSILON);
	assert(abs(cosh(1)-1.5430806348) < EPSILON);
	assert(abs(cosh(2)-3.7621956911) < EPSILON);
}
test_cosh();


module test_tanh() {
	assert(abs(tanh(-2)+0.9640275801) < EPSILON);
	assert(abs(tanh(-1)+0.761594156) < EPSILON);
	assert(abs(tanh(0)) < EPSILON);
	assert(abs(tanh(1)-0.761594156) < EPSILON);
	assert(abs(tanh(2)-0.9640275801) < EPSILON);
}
test_tanh();


module test_asinh() {
	assert(abs(asinh(sinh(-2))+2) < EPSILON);
	assert(abs(asinh(sinh(-1))+1) < EPSILON);
	assert(abs(asinh(sinh(0))) < EPSILON);
	assert(abs(asinh(sinh(1))-1) < EPSILON);
	assert(abs(asinh(sinh(2))-2) < EPSILON);
}
test_asinh();


module test_acosh() {
	assert(abs(acosh(cosh(-2))-2) < EPSILON);
	assert(abs(acosh(cosh(-1))-1) < EPSILON);
	assert(abs(acosh(cosh(0))) < EPSILON);
	assert(abs(acosh(cosh(1))-1) < EPSILON);
	assert(abs(acosh(cosh(2))-2) < EPSILON);
}
test_acosh();


module test_atanh() {
	assert(abs(atanh(tanh(-2))+2) < EPSILON);
	assert(abs(atanh(tanh(-1))+1) < EPSILON);
	assert(abs(atanh(tanh(0))) < EPSILON);
	assert(abs(atanh(tanh(1))-1) < EPSILON);
	assert(abs(atanh(tanh(2))-2) < EPSILON);
}
test_atanh();


module test_sum() {
	assert(sum([1,2,3]) == 6);
	assert(sum([-2,-1,0,1,2]) == 0);
	assert(sum([[1,2,3], [3,4,5], [5,6,7]]) == [9,12,15]);
}
test_sum();


module test_sum_of_squares() {
	assert(sum_of_squares([1,2,3]) == 14);
	assert(sum_of_squares([1,2,4]) == 21);
	assert(sum_of_squares([-3,-2,-1]) == 14);
}
test_sum_of_squares();


module test_sum_of_sines() {
	assert(sum_of_sines(0, [[3,4,0],[2,2,0]]) == 0);
	assert(sum_of_sines(45, [[3,4,0],[2,2,0]]) == 2);
	assert(sum_of_sines(90, [[3,4,0],[2,2,0]]) == 0);
	assert(sum_of_sines(135, [[3,4,0],[2,2,0]]) == -2);
	assert(sum_of_sines(180, [[3,4,0],[2,2,0]]) == 0);
}
test_sum_of_sines();


module test_deltas() {
	assert(deltas([2,5,9,17]) == [3,4,8]);
	assert(deltas([[1,2,3], [3,6,8], [4,8,11]]) == [[2,4,5], [1,2,3]]);
}
test_deltas();


module test_product() {
	assert(product([2,3,4]) == 24);
	assert(product([[1,2,3], [3,4,5], [5,6,7]]) == [15, 48, 105]);
	m1 = [[2,3,4],[4,5,6],[6,7,8]];
	m2 = [[4,1,2],[3,7,2],[8,7,4]];
	m3 = [[3,7,8],[9,2,4],[5,8,3]];
	assert(product([m1,m2,m3]) == m1*m2*m3);
}
test_product();


module test_mean() {
	assert(mean([2,3,4]) == 3);
	assert(mean([[1,2,3], [3,4,5], [5,6,7]]) == [3,4,5]);
}
test_mean();


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
	assert(any([0,false,undef]) == false);
	assert(any([1,false,undef]) == true);
	assert(any([1,5,true]) == true);
	assert(any([[0,0], [0,0]]) == false);
	assert(any([[0,0], [1,0]]) == true);
}
test_any();


module test_all() {
	assert(all([0,false,undef]) == false);
	assert(all([1,false,undef]) == false);
	assert(all([1,5,true]) == true);
	assert(all([[0,0], [0,0]]) == false);
	assert(all([[0,0], [1,0]]) == false);
	assert(all([[1,1], [1,1]]) == true);
}
test_all();


module test_count_true() {
	assert(count_true([0,false,undef]) == 0);
	assert(count_true([1,false,undef]) == 1);
	assert(count_true([1,5,false]) == 2);
	assert(count_true([1,5,true]) == 3);
	assert(count_true([[0,0], [0,0]]) == 0);
	assert(count_true([[0,0], [1,0]]) == 1);
	assert(count_true([[1,1], [1,1]]) == 4);
	assert(count_true([[1,1], [1,1]], nmax=3) == 3);
}
test_count_true();




// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
