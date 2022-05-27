include <../std.scad>


module test_num_true() {
    assert_equal(num_true([0,false,undef]), 0);
    assert_equal(num_true([1,false,undef]), 1);
    assert_equal(num_true([1,5,false]), 2);
    assert_equal(num_true([1,5,true]), 3);
    assert_equal(num_true([[0,0], [0,0]]), 2);
    assert_equal(num_true([[0,0], [1,0]]), 2);
    assert_equal(num_true([[], [1,1]]), 1);
    assert_equal(num_true([1,3,5,7,9], function (a) a%2==0),0);
    assert_equal(num_true([1,3,6,8,9], function (a) a%2==0),2);
    assert_equal(num_true([1,3,5,7,9], function (a) a%2!=0),5);
}
test_num_true();



module test_typeof() {
    assert(typeof(undef) == "undef");
    assert(typeof(true) == "boolean");
    assert(typeof(false) == "boolean");
    assert(typeof(-123) == "number");
    assert(typeof(0) == "number");
    assert(typeof(123) == "number");
    assert(typeof("") == "string");
    assert(typeof("foo") == "string");
    assert(typeof([]) == "list");
    assert(typeof(["foo","bar"]) == "list");
    assert(typeof([123,849,32]) == "list");
    assert(typeof([0:5]) == "range");
    assert(typeof([-3:0]) == "range");
    assert(typeof([0:1:5]) == "range");
    assert(typeof([-3:2:5]) == "range");
    assert(typeof([10:-2:-10]) == "range");
    assert(typeof([0:NAN:INF]) == "invalid");
    assert(typeof([0:"a":INF]) == "undef"); 
    assert(typeof([0:[]:INF]) == "undef"); 
    assert(typeof([true:1:INF]) == "undef"); 
}
test_typeof();


module test_is_type() {
    assert(is_type(undef,"undef"));
    assert(is_type(true,"boolean"));
    assert(is_type(false,"boolean"));
    assert(is_type(-123,"number"));
    assert(is_type(0,"number"));
    assert(is_type(123,"number"));
    assert(is_type("","string"));
    assert(is_type("foo","string"));
    assert(is_type([],"list"));
    assert(is_type([1,2,3],"list"));
    assert(is_type(["foo","bar"],"list"));
    assert(is_type([0:5],"range"));

    assert(is_type(undef,["undef"]));
    assert(is_type(true,["boolean"]));
    assert(is_type(false,["boolean"]));
    assert(is_type(-123,["number"]));
    assert(is_type(0,["number"]));
    assert(is_type(123,["number"]));
    assert(is_type("",["string"]));
    assert(is_type("foo",["string"]));
    assert(is_type([],["list"]));
    assert(is_type([1,2,3],["list"]));
    assert(is_type(["foo","bar"],["list"]));
    assert(is_type([0:5],["range"]));

    assert(is_type(123,["number","string"]));
    assert(is_type("foo",["number","string"]));
}
test_is_type();


module test_is_def() {
    assert(!is_def(undef));
    assert(is_def(true));
    assert(is_def(false));
    assert(is_def(-123));
    assert(is_def(0));
    assert(is_def(123));
    assert(is_def(""));
    assert(is_def("foo"));
    assert(is_def([]));
    assert(is_def([3,4,5]));
    assert(is_def(["foo","bar","baz"]));
    assert(is_def([0:5]));
}
test_is_def();


module test_segs() {
    assert_equal(segs(50,$fn=8), 8);
    assert_equal(segs(50,$fa=2,$fs=2), 158);
}
test_segs();




module test_is_str() {
    assert(!is_str(undef));
    assert(!is_str(true));
    assert(!is_str(false));
    assert(!is_str(-123));
    assert(!is_str(0));
    assert(!is_str(123));
    assert(is_str(""));
    assert(is_str("foo"));
    assert(!is_str([]));
    assert(!is_str([3,4,5]));
    assert(!is_str(["foo","bar","baz"]));
    assert(!is_str([0:5]));
}
test_is_str();


module test_is_int() {
    assert(is_int(-999));
    assert(is_int(-1));
    assert(is_int(0));
    assert(is_int(1));
    assert(is_int(999));
    assert(!is_int(-1.1));
    assert(!is_int(1.1));
    assert(!is_int(-0.1));
    assert(!is_int(0.1));
    assert(!is_int(-99.1));
    assert(!is_int(99.1));
    assert(!is_int(undef));
    assert(!is_int(INF));
    assert(!is_int(NAN));
    assert(!is_int(false));
    assert(!is_int(true));
    assert(!is_int("foo"));
    assert(!is_int([0,1,2]));
    assert(!is_int([0:1:2]));
}
test_is_int();


module test_is_integer() {
    assert(is_integer(-999));
    assert(is_integer(-1));
    assert(is_integer(0));
    assert(is_integer(1));
    assert(is_integer(999));
    assert(!is_integer(-1.1));
    assert(!is_integer(1.1));
    assert(!is_integer(-0.1));
    assert(!is_integer(0.1));
    assert(!is_integer(-99.1));
    assert(!is_integer(99.1));
    assert(!is_integer(undef));
    assert(!is_integer(INF));
    assert(!is_integer(NAN));
    assert(!is_integer(false));
    assert(!is_integer(true));
    assert(!is_integer("foo"));
    assert(!is_integer([0,1,2]));
    assert(!is_integer([0:1:2]));
}
test_is_integer();


module test_is_nan() {
    assert(!is_nan(undef));
    assert(!is_nan(true));
    assert(!is_nan(false));
    assert(!is_nan(-5));
    assert(!is_nan(0));
    assert(!is_nan(5));
    assert(!is_nan(INF));
    assert(!is_nan(-INF));
    assert(!is_nan(""));
    assert(!is_nan("foo"));
    assert(!is_nan([]));
    assert(!is_nan([3,4,5]));
    assert(!is_nan([3:1:5]));
    assert(is_nan(NAN));
}
test_is_nan();


module test_is_finite() {
    assert(!is_finite(undef));
    assert(!is_finite(true));
    assert(!is_finite(false));
    assert(is_finite(-5));
    assert(is_finite(0));
    assert(is_finite(5));
    assert(!is_finite(INF));
    assert(!is_finite(-INF));
    assert(!is_finite(""));
    assert(!is_finite("foo"));
    assert(!is_finite([]));
    assert(!is_finite([3,4,5]));
    assert(!is_finite([3:1:5]));
    assert(!is_finite(NAN));
}
test_is_finite();


module test_is_range() {
    assert(!is_range(undef));
    assert(!is_range(true));
    assert(!is_range(false));
    assert(!is_range(-5));
    assert(!is_range(0));
    assert(!is_range(5));
    assert(!is_range(INF));
    assert(!is_range(-INF));
    assert(!is_range(""));
    assert(!is_range("foo"));
    assert(!is_range([]));
    assert(!is_range([3,4,5]));
    assert(!is_range([INF:4:5]));
    assert(!is_range([3:NAN:5]));
    assert(!is_range([3:4:"a"]));
    assert(is_range([3:1:5]));
}
test_is_range();


module test_valid_range() {
    assert(valid_range([0:0]));
    assert(valid_range([0:1:0]));
    assert(valid_range([0:1:10]));
    assert(valid_range([0.1:1.1:2.1]));
    assert(valid_range([0:-1:0]));
    assert(valid_range([10:-1:0]));
    assert(valid_range([2.1:-1.1:0.1]));
    if (version_num() < 20200600) {
        assert(!valid_range([10:1:0]));
        assert(!valid_range([2.1:1.1:0.1]));
        assert(!valid_range([0:-1:10]));
        assert(!valid_range([0.1:-1.1:2.1]));
    }
}
test_valid_range();

module test_is_consistent() {
    assert(is_consistent([]));
    assert(is_consistent([[],[]]));
    assert(is_consistent([3,4,5]));
    assert(is_consistent([[3,4],[4,5],[6,7]]));
    assert(is_consistent([[[3],4],[[4],5]]));
    assert(!is_consistent(5));
    assert(!is_consistent(undef));
    assert(!is_consistent([[3,4,5],[3,4]]));
    assert(is_consistent([[3,[3,4,[5]]], [5,[2,9,[9]]]]));
    assert(!is_consistent([[3,[3,4,[5]]], [5,[2,9,9]]]));

    assert(is_consistent([3,4,5], 0));
    assert(!is_consistent([3,4,undef], 0));
    assert(is_consistent([[3,4],[4,5]], [1,1]));
    assert(!is_consistent([[3,4], 6, [4,5]], [1,1]));
    assert(is_consistent([[1,[3,4]], [4,[5,6]]], [1,[2,3]]));
    assert(!is_consistent([[1,[3,INF]], [4,[5,6]]], [1,[2,3]]));
}
test_is_consistent();


module test_same_shape() {
    assert(same_shape([3,[4,5]],[7,[3,4]]));
    assert(!same_shape([3,4,5], [7,[3,4]]));
    assert(!same_shape([3,4,5],undef));
    assert(!same_shape([5,3],3));
    assert(!same_shape(undef,[3,4]));
    assert(same_shape(4,5));
    assert(!same_shape(5,undef));
           
}
test_same_shape();


module test_default() {
    assert(default(undef,23) == 23);
    assert(default(true,23) == true);
    assert(default(false,23) == false);
    assert(default(-123,23) == -123);
    assert(default(0,23) == 0);
    assert(default(123,23) == 123);
    assert(default("",23) == "");
    assert(default("foo",23) == "foo");
}
test_default();


module test_first_defined() {
    assert(first_defined([undef,undef,true,false,undef]) == true);
    assert(first_defined([undef,undef,false,true,undef]) == false);
    assert(first_defined([undef,undef,0,1,undef]) == 0);
    assert(first_defined([undef,undef,43,44,undef]) == 43);
    assert(first_defined([undef,undef,"foo","bar",undef]) == "foo");
    assert(first_defined([0,1,2,3,4]) == 0);
    assert(first_defined([2,3,4]) == 2);
    assert(first_defined([[undef,undef],[undef,true],[false,undef]],recursive=true) == [undef, true]);
}
test_first_defined();


module test_one_defined() {
    assert_equal(one_defined([27,undef,undef], "length,L,l") ,27);
    assert_equal(one_defined([undef,28,undef], "length,L,l") ,28);
    assert_equal(one_defined([undef,undef,29], "length,L,l") ,29);
    assert_equal(one_defined([undef,undef,undef], "length,L,l", dflt=undef), undef);
    assert_equal(one_defined([27,undef,undef], ["length","L","l"]) ,27);
    assert_equal(one_defined([undef,28,undef], ["length","L","l"]) ,28);
    assert_equal(one_defined([undef,undef,29], ["length","L","l"]) ,29);
    assert_equal(one_defined([undef,undef,undef], ["length","L","l"], dflt=undef), undef);
}
test_one_defined();


module test_num_defined() {
    assert(num_defined([undef,undef,true,false,undef]) == 2);
    assert(num_defined([9,undef,true,false,undef]) == 3);
    assert(num_defined([undef,9,true,false,undef]) == 3);
    assert(num_defined(["foo",9,true,false,undef]) == 4);
}
test_num_defined();


module test_any_defined() {
    assert(!any_defined([undef,undef,undef,undef,undef]));
    assert(any_defined([3,undef,undef,undef,undef]));
    assert(any_defined([undef,3,undef,undef,undef]));
    assert(any_defined([undef,undef,3,undef,undef]));
    assert(any_defined([undef,undef,undef,3,undef]));
    assert(any_defined([undef,undef,undef,undef,3]));
    assert(any_defined([3,undef,undef,undef,3]));
    assert(any_defined([3,3,3,3,3]));
    assert(any_defined(["foo",undef,undef,undef,undef]));
    assert(any_defined([undef,"foo",undef,undef,undef]));
    assert(any_defined([undef,undef,"foo",undef,undef]));
    assert(any_defined([undef,undef,undef,"foo",undef]));
    assert(any_defined([undef,undef,undef,undef,"foo"]));
    assert(any_defined(["foo",undef,undef,undef,"foo"]));
    assert(any_defined(["foo","foo","foo","foo","foo"]));
    assert(any_defined([undef,undef,true,false,undef]));
}
test_any_defined();


module test_all_defined() {
    assert(!all_defined([undef,undef,undef,undef,undef]));
    assert(!all_defined([3,undef,undef,undef,undef]));
    assert(!all_defined([undef,3,undef,undef,undef]));
    assert(!all_defined([undef,undef,3,undef,undef]));
    assert(!all_defined([undef,undef,undef,3,undef]));
    assert(!all_defined([undef,undef,undef,undef,3]));
    assert(!all_defined([3,undef,undef,undef,3]));
    assert(all_defined([3,3,3,3,3]));
    assert(!all_defined(["foo",undef,undef,undef,undef]));
    assert(!all_defined([undef,"foo",undef,undef,undef]));
    assert(!all_defined([undef,undef,"foo",undef,undef]));
    assert(!all_defined([undef,undef,undef,"foo",undef]));
    assert(!all_defined([undef,undef,undef,undef,"foo"]));
    assert(!all_defined(["foo",undef,undef,undef,"foo"]));
    assert(all_defined(["foo","foo","foo","foo","foo"]));
    assert(!all_defined([undef,undef,true,false,undef]));
}
test_all_defined();


module test_get_anchor() {
    assert_equal(get_anchor(UP,true,-[1,1,1],BOT),CENTER);
    assert_equal(get_anchor(UP,false,-[1,1,1],BOT),-[1,1,1]);
    assert_equal(get_anchor(UP,undef,-[1,1,1],BOT),UP);
    assert_equal(get_anchor(undef,true,-[1,1,1],BOT),CENTER);
    assert_equal(get_anchor(undef,false,-[1,1,1],BOT),-[1,1,1]);
    assert_equal(get_anchor(undef,undef,-[1,1,1],BOT),BOT);
}
test_get_anchor();


module test_get_radius() {
    assert(get_radius(r1=100,d1=undef,r=undef,d=undef,dflt=23) == 100);
    assert(get_radius(r1=undef,d1=200,r=undef,d=undef,dflt=23) == 100);
    assert(get_radius(r1=undef,d1=undef,r=100,d=undef,dflt=23) == 100);
    assert(get_radius(r1=undef,d1=undef,r=undef,d=200,dflt=23) == 100);
    assert(get_radius(r1=50,d1=undef,r=undef,d=undef,dflt=23) == 50);
    assert(get_radius(r1=undef,d1=100,r=undef,d=undef,dflt=23) == 50);
    assert(get_radius(r1=undef,d1=undef,r=50,d=undef,dflt=23) == 50);
    assert(get_radius(r1=undef,d1=undef,r=undef,d=100,dflt=23) == 50);
    assert(get_radius(r1=undef,d1=undef,r=undef,d=undef,dflt=23) == 23);
    assert(get_radius(r1=undef,d1=undef,r=undef,d=undef,dflt=undef) == undef);
}
test_get_radius();


module test_scalar_vec3() {
    assert(scalar_vec3(undef) == undef);
    assert(scalar_vec3(3) == [3,3,3]);
    assert(scalar_vec3(3,dflt=1) == [3,1,1]);
    assert(scalar_vec3([3]) == [3,0,0]);
    assert(scalar_vec3([3,4]) == [3,4,0]);
    assert(scalar_vec3([3,4],dflt=1) == [3,4,1]);
    assert(scalar_vec3([3,"a"],dflt=1) == [3,"a",1]);
    assert(scalar_vec3([3,[2]],dflt=1) == [3,[2],1]);
    assert(scalar_vec3([3],dflt=1) == [3,1,1]);
    assert(scalar_vec3([3,4,5]) == [3,4,5]);
    assert(scalar_vec3([3,4,5,6]) == [3,4,5]);
    assert(scalar_vec3([3,4,5,6]) == [3,4,5]);
}
test_scalar_vec3();


module test_segs() {
    assert_equal(segs(50,$fn=8), 8);
    assert_equal(segs(50,$fa=2,$fs=2), 158);
    assert(segs(1)==5);
    assert(segs(11)==30);
  //  assert(segs(1/0)==5);
  //  assert(segs(0/0)==5);
  //  assert(segs(undef)==5);
}
test_segs();

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
