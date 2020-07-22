include <../std.scad>
include <../stacks.scad>


module test_stack_init() {
    assert(stack_init()==[]);
}
test_stack_init();


module test_stack_empty() {
    assert(stack_empty([]));
    assert(!stack_empty([3]));
    assert(!stack_empty([2,4,8]));
}
test_stack_empty();


module test_stack_depth() {
    assert(stack_depth([]) == 0);
    assert(stack_depth([3]) == 1);
    assert(stack_depth([2,4,8]) == 3);
}
test_stack_depth();


module test_stack_top() {
    assert(stack_top([]) == undef);
    assert(stack_top([3,5,7,9]) == 9);
    assert(stack_top([3,5,7,9], 3) == [5,7,9]);
}
test_stack_top();


module test_stack_peek() {
    s = [8,5,4,3,2,3,7];
    assert(stack_peek(s,0) == 7);
    assert(stack_peek(s,2) == 2);
    assert(stack_peek(s,2,1) == [2]);
    assert(stack_peek(s,2,3) == [2,3,7]);
}
test_stack_peek();


module test_stack_push() {
    s1 = stack_init();
    s2 = stack_push(s1, "Foo");
    assert(s2==["Foo"]);
    s3 = stack_push(s2, "Bar");
    assert(s3==["Foo","Bar"]);
    s4 = stack_push(s3, "Baz");
    assert(s4==["Foo","Bar","Baz"]);
}
test_stack_push();


module test_stack_pop() {
    s = ["Foo", "Bar", "Baz", "Qux"];
    s1 = stack_pop(s);
    assert(s1 == ["Foo", "Bar", "Baz"]);
    s2 = stack_pop(s,2);
    assert(s2 == ["Foo", "Bar"]);
    s3 = stack_pop(s,3);
    assert(s3 == ["Foo"]);
}
test_stack_pop();


module test_stack_rotate() {
    s = ["Foo", "Bar", "Baz", "Qux", "Quux"];
    s1 = stack_rotate(s,4);
    assert(s1 == ["Foo", "Baz", "Qux", "Quux", "Bar"]);
    s2 = stack_rotate(s,-4);
    assert(s2 == ["Foo", "Quux", "Bar", "Baz", "Qux"]);
}
test_stack_rotate();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
