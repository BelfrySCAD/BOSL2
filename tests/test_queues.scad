include <../std.scad>
include <../queues.scad>


module test_queue_init() {
    assert(queue_init()==[]);
}
test_queue_init();


module test_queue_empty() {
    assert(queue_empty([]));
    assert(!queue_empty([3]));
    assert(!queue_empty([2,4,8]));
}
test_queue_empty();


module test_queue_size() {
    assert(queue_size([]) == 0);
    assert(queue_size([3]) == 1);
    assert(queue_size([2,4,8]) == 3);
}
test_queue_size();


module test_queue_head() {
    assert(queue_head([]) == undef);
    assert(queue_head([3,5,7,9]) == 3);
    assert(queue_head([3,5,7,9], 3) == [3,5,7]);
}
test_queue_head();


module test_queue_tail() {
    assert(queue_tail([]) == undef);
    assert(queue_tail([3,5,7,9]) == 9);
    assert(queue_tail([3,5,7,9], 3) == [5,7,9]);
}
test_queue_tail();


module test_queue_peek() {
    q = [8,5,4,3,2,3,7];
    assert(queue_peek(q,0) == 8);
    assert(queue_peek(q,2) == 4);
    assert(queue_peek(q,2,1) == [4]);
    assert(queue_peek(q,2,3) == [4,3,2]);
}
test_queue_peek();


module test_queue_add() {
    q1 = queue_init();
    q2 = queue_add(q1, "Foo");
    assert(q2==["Foo"]);
    q3 = queue_add(q2, "Bar");
    assert(q3==["Foo","Bar"]);
    q4 = queue_add(q3, "Baz");
    assert(q4==["Foo","Bar","Baz"]);
}
test_queue_add();


module test_queue_pop() {
    q = ["Foo", "Bar", "Baz", "Qux"];
    q1 = queue_pop(q);
    assert(q1 == ["Bar", "Baz", "Qux"]);
    q2 = queue_pop(q,2);
    assert(q2 == ["Baz", "Qux"]);
    q3 = queue_pop(q,3);
    assert(q3 == ["Qux"]);
}
test_queue_pop();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
