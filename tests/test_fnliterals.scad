include <../std.scad>
include <../fnliterals.scad>


module test_map() {
    l1 = [1,2,3,4,5,6,7,8];
    l2 = [7,3,9,1,6,1,3,2];
    x3 = function (x) x*3;
    d3 = function (x) x/3;
    xx = function (x) x*x;
    assert_approx(map(x3,l1), l1*3);
    assert_approx(map(x3,l2), l2*3);
    assert_approx(map(d3,l1), l1/3);
    assert_approx(map(d3,l2), l2/3);
    assert_approx(map(xx,l1), [for (x=l1) x*x]);
    assert_approx(map(xx,l2), [for (x=l2) x*x]);
}
test_map();


module test_filter() {
    l = [7,3,9,1,6,1,3,2];
    lt3 = function (x) x<3;
    lte3 = function (x) x<=3;
    gt3 = function (x) x>3;
    gte3 = function (x) x>=3;
    assert_equal(filter(lt3,l), [1,1,2]);
    assert_equal(filter(lte3,l), [3,1,1,3,2]);
    assert_equal(filter(gt3,l), [7,9,6]);
    assert_equal(filter(gte3,l), [7,3,9,6,3]);
}
test_filter();


module test_reduce() {
    l = [7,3,9,1,6,1,3,2];
    add = function (a,b) a+b;
    mul = function (a,b) a*b;
    assert_equal(reduce(add,l), 32);
    assert_equal(reduce(mul,l), 0);
    assert_equal(reduce(mul,l,init=1), 6804);
}
test_reduce();


module test_accumulate() {
    l = [2,3,9,1,6,1,3,2];
    add = function (a,b) a+b;
    mul = function (a,b) a*b;
    assert_equal(accumulate(add,l), [2,5,14,15,21,22,25,27]);
    assert_equal(accumulate(mul,l), [0,0,0,0,0,0,0,0]);
    assert_equal(accumulate(mul,l,init=1), [2,6,54,54,324,324,972,1944]);
}
test_accumulate();


module test_while() {
    fibs = while(
        init = [1,1],
        cond = function (i,x) select(x,-1)<25,
        func = function (i,x) concat(x, [sum(select(x,-2,-1))])
    );
    assert_equal(fibs, [1,1,2,3,5,8,13,21,34]);
}
test_while();


module test_for_n() {
    fib = function(n) for_n(
        n, [],
        function(i,x) x? [x[1], x[0]+x[1]] : [0,1]
    )[1];
    assert_equal(fib(1),1);
    assert_equal(fib(2),1);
    assert_equal(fib(3),2);
    assert_equal(fib(4),3);
    assert_equal(fib(5),5);
    assert_equal(fib(6),8);
    assert_equal(fib(7),13);
    assert_equal(fib(8),21);
}
test_for_n();


module test_find_first() {
    l = [7,3,9,1,6,1,3,2];
    lt  = function (val,x) val <  x;
    lte = function (val,x) val <= x;
    gt  = function (val,x) val >  x;
    gte = function (val,x) val >= x;
    assert_equal(find_first(1,l), 3);
    assert_equal(find_first(1,l,start=4), 5);
    assert_equal(find_first(6,l), 4);
    assert_equal(find_first(3,l,func=gt ), 3);
    assert_equal(find_first(3,l,func=gte), 1);
    assert_equal(find_first(3,l,func=lt ), 0);
    assert_equal(find_first(7,l,func=lt ), 2);
    assert_equal(find_first(7,l,func=lte), 0);
    assert_equal(find_first(7,l,start=1,func=gte), 1);
    assert_equal(find_first(7,l,start=3,func=gte), 3);
}
//test_find_first();


module test_binsearch() {
    l = [3,6,7,9,10,11,13,17,18,19,22,47,53,68,72,79,81,84,85,88,97];
    assert_equal(binsearch(1,l), undef);
    assert_equal(binsearch(43,l), undef);
    assert_equal(binsearch(93,l), undef);
    assert_equal(binsearch(99,l), undef);
    for (i=idx(l)) {
        assert_equal(binsearch(l[i],l), i);
    }
}
test_binsearch();


module test_simple_hash() {
    assert_equal(simple_hash(true), 1000398);
    assert_equal(simple_hash(false), 1028531);
    assert_equal(simple_hash(53), 8385);
    assert_equal(simple_hash("Foobar"), 1065337);
    assert_equal(simple_hash([]), 0);
    assert_equal(simple_hash([[10,20],[-5,3]]), 42685374681);
}
test_simple_hash();


module test_f_1arg() {
    assert_equal(str(f_1arg(function (x) x)), "function(a) ((a == undef) ? function(x) func(x) : function() func(a))");
    assert_equal(str(f_1arg(function (x) x)(3)), "function() func(a)");
    assert_equal(f_1arg(function (x) x)()(4), 4);
    assert_equal(f_1arg(function (x) x)(3)(), 3);
}
test_f_1arg();


module test_f_2arg() {
    assert_equal(str(f_2arg(function (a,b) a+b)), "function(a, b) (((a == undef) && (b == undef)) ? function(x, y) func(x, y) : ((a == undef) ? function(x) func(x, b) : ((b == undef) ? function(x) func(a, x) : function() func(a, b))))");
    assert_equal(str(f_2arg(function (a,b) a+b)(3)), "function(x) func(a, x)");
    assert_equal(str(f_2arg(function (a,b) a+b)(a=3)), "function(x) func(a, x)");
    assert_equal(str(f_2arg(function (a,b) a+b)(b=3)), "function(x) func(x, b)");
    assert_equal(str(f_2arg(function (a,b) a+b)(3,4)), "function() func(a, b)");
    assert_equal(f_2arg(function (a,b) a+b)()(4,2), 6);
    assert_equal(f_2arg(function (a,b) a+b)(3)(7), 10);
    assert_equal(f_2arg(function (a,b) a+b)(a=2)(7), 9);
    assert_equal(f_2arg(function (a,b) a/b)(a=8)(2), 4);
}
test_f_2arg();


module test_f_3arg() {
    assert_equal(str(f_3arg(function (a,b,c) a+b+c)), "function(a, b, c) ((((a == undef) && (b == undef)) && (c == undef)) ? func : (((a == undef) && (b == undef)) ? function(x, y) func(x, y, c) : (((a == undef) && (c == undef)) ? function(x, y) func(x, b, y) : (((b == undef) && (c == undef)) ? function(x, y) func(a, x, y) : ((a == undef) ? function(x) func(x, b, c) : ((b == undef) ? function(x) func(a, x, c) : ((c == undef) ? function(x) func(a, b, x) : function() func(a, b, c))))))))");
    assert_equal(str(f_3arg(function (a,b,c) a+b+c)(3)), "function(x, y) func(a, x, y)");
    assert_equal(str(f_3arg(function (a,b,c) a+b+c)(3,4)), "function(x) func(a, b, x)");
    assert_equal(str(f_3arg(function (a,b,c) a+b+c)(3,4,1)), "function() func(a, b, c)");
    assert_equal(f_3arg(function (a,b,c) a+b+c)()(4,2,1), 7);
    assert_equal(f_3arg(function (a,b,c) a+b+c)(3)(7,3), 13);
    assert_equal(f_3arg(function (a,b,c) a+b+c)(a=2)(7,1), 10);
    assert_equal(f_3arg(function (a,b,c) a/b/c)(a=24)(3,2), 4);
    assert_equal(f_3arg(function (a,b,c) a+b+c)(3,7)(3), 13);
    assert_equal(f_3arg(function (a,b,c) a+b+c)(3,7,3)(), 13);
}
test_f_3arg();


module test_ival() {
    assert_equal(str(ival(function (a) a)), "function(a, b) func(a)");
    assert_equal(ival(function (a) a)(3,5), 3);
}
test_ival();


module test_xval() {
    assert_equal(str(xval(function (a) a)), "function(a, b) func(b)");
    assert_equal(xval(function (a) a)(3,5), 5);
}
test_xval();


module _test_fn1arg(dafunc,tests) {
    assert_equal(str(dafunc()),    "function(x) func(x)");
    assert_equal(str(dafunc(3)),   "function() func(a)");
    for (test = tests) {
        a = test[0];
        r = test[1];
        assert_equal(dafunc(a)(), r);
        assert_equal(dafunc()(a), r);
    }
}


module _test_fn2arg(dafunc,tests) {
    assert_equal(str(dafunc()),    "function(x, y) func(x, y)");
    assert_equal(str(dafunc(3)),   "function(x) func(a, x)");
    assert_equal(str(dafunc(a=3)), "function(x) func(a, x)");
    assert_equal(str(dafunc(b=3)), "function(x) func(x, b)");
    assert_equal(str(dafunc(3,4)), "function() func(a, b)");
    for (test = tests) {
        a = test[0];
        b = test[1];
        r = test[2];
        assert_equal(dafunc(a=a,b=b)(), r);
        assert_equal(dafunc(a,b)(), r);
        assert_equal(dafunc(a)(b), r);
        assert_equal(dafunc(a=a)(b), r);
        assert_equal(dafunc(b=b)(a), r);
        assert_equal(dafunc()(a,b), r);
    }
}


module test_f_cmp() {
    _test_fn2arg(
        function (a,b) f_cmp(a,b),
        [[4,3,1],[3,3,0],[3,4,-1]]
    );
}
test_f_cmp();


module test_f_gt() {
    _test_fn2arg(
        function (a,b) f_gt(a,b),
        [[4,3,true],[3,3,false],[3,4,false]]
    );
}
test_f_gt();


module test_f_gte() {
    _test_fn2arg(
        function (a,b) f_gte(a,b),
        [[4,3,true],[3,3,true],[3,4,false]]
    );
}
test_f_gte();


module test_f_lt() {
    _test_fn2arg(
        function (a,b) f_lt(a,b),
        [[4,3,false],[3,3,false],[3,4,true]]
    );
}
test_f_lt();


module test_f_lte() {
    _test_fn2arg(
        function (a,b) f_lte(a,b),
        [[4,3,false],[3,3,true],[3,4,true]]
    );
}
test_f_lte();


module test_f_eq() {
    _test_fn2arg(
        function (a,b) f_eq(a,b),
        [[4,3,false],[3,3,true],[3,4,false]]
    );
}
test_f_eq();


module test_f_neq() {
    _test_fn2arg(
        function (a,b) f_neq(a,b),
        [[4,3,true],[3,3,false],[3,4,true]]
    );
}
test_f_neq();


module test_f_approx() {
    _test_fn2arg(
        function (a,b) f_approx(a,b),
        [[4,3,false],[3,3,true],[3,4,false],[1/3,0.33333333333333333333333333,true]]
    );
}
test_f_approx();


module test_f_napprox() {
    _test_fn2arg(
        function (a,b) f_napprox(a,b),
        [[4,3,true],[3,3,false],[3,4,true],[1/3,0.33333333333333333333333333,false]]
    );
}
test_f_napprox();


module test_f_or() {
    _test_fn2arg(
        function (a,b) f_or(a,b),
        [
            [false, false, false],
            [true , false, true ],
            [false, true , true ],
            [true , true , true ]
        ]
    );
}
test_f_or();


module test_f_and() {
    _test_fn2arg(
        function (a,b) f_and(a,b),
        [
            [false, false, false],
            [true , false, false],
            [false, true , false],
            [true , true , true ]
        ]
    );
}
test_f_and();


module test_f_nor() {
    _test_fn2arg(
        function (a,b) f_nor(a,b),
        [
            [false, false, true ],
            [true , false, false],
            [false, true , false],
            [true , true , false]
        ]
    );
}
test_f_nor();


module test_f_nand() {
    _test_fn2arg(
        function (a,b) f_nand(a,b),
        [
            [false, false, true ],
            [true , false, true ],
            [false, true , true ],
            [true , true , false]
        ]
    );
}
test_f_nand();


module test_f_xor() {
    _test_fn2arg(
        function (a,b) f_xor(a,b),
        [
            [false, false, false],
            [true , false, true ],
            [false, true , true ],
            [true , true , false]
        ]
    );
}
test_f_xor();


module test_f_not() {
    _test_fn1arg(
        function (a) f_not(a),
        [
            [true,  false],
            [false, true ],
        ]
    );
}
test_f_not();


module test_f_even() {
    _test_fn1arg(
        function (a) f_even(a),
        [
            [-3, false],
            [-2, true ],
            [-1, false],
            [ 0, true ],
            [ 1, false],
            [ 2, true ],
            [ 3, false],
        ]
    );
}
test_f_even();


module test_f_odd() {
    _test_fn1arg(
        function (a) f_odd(a),
        [
            [-3, true ],
            [-2, false],
            [-1, true ],
            [ 0, false],
            [ 1, true ],
            [ 2, false],
            [ 3, true ],
        ]
    );
}
test_f_odd();


module test_f_add() {
    _test_fn2arg(
        function (a,b) f_add(a,b),
        [[4,3,7],[3,3,6],[3,2,5],[-3,-5,-8],[-3,7,4],[3,-7,-4]]
    );
}
test_f_add();


module test_f_sub() {
    _test_fn2arg(
        function (a,b) f_sub(a,b),
        [[4,3,1],[3,3,0],[3,4,-1],[-3,-5,2],[-3,6,-9],[3,-6,9]]
    );
}
test_f_sub();


module test_f_mul() {
    _test_fn2arg(
        function (a,b) f_mul(a,b),
        [[4,3,12],[3,3,9],[3,2,6],[-3,-5,15],[-3,7,-21],[3,-7,-21]]
    );
}
test_f_mul();


module test_f_div() {
    _test_fn2arg(
        function (a,b) f_div(a,b),
        [[21,3,7],[21,7,3],[16,4,4],[-16,4,-4],[-16,-4,4]]
    );
}
test_f_div();


module test_f_mod() {
    _test_fn2arg(
        function (a,b) f_mod(a,b),
        [[21,3,0],[22,7,1],[23,3,2],[24,3,0]]
    );
}
test_f_mod();


module test_f_pow() {
    _test_fn2arg(
        function (a,b) f_pow(a,b),
        [[2,3,8],[3,3,27],[4,2,16],[2,-3,1/8]]
    );
}
test_f_pow();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
