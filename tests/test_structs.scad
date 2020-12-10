include <../std.scad>
include <../structs.scad>


module test_struct_set() {
    st = struct_set([], "Foo", 42);
    assert(st == [["Foo",42]]);
    st2 = struct_set(st, "Bar", 28);
    assert(st2 == [["Foo",42],["Bar",28]]);
    st3 = struct_set(st2, "Foo", 91);
    assert(st3 == [["Foo",91],["Bar",28]]);
}
test_struct_set();


module test_struct_remove() {
    st = [["Foo",91],["Bar",28],["Baz",9]];
    assert(struct_remove(st, "Foo") == [["Bar",28],["Baz",9]]);
    assert(struct_remove(st, "Bar") == [["Foo",91],["Baz",9]]);
    assert(struct_remove(st, "Baz") == [["Foo",91],["Bar",28]]);
}
test_struct_remove();


module test_struct_val() {
    st = [["Foo",91],["Bar",28],["Baz",9]];
    assert(struct_val(st,"Foo") == 91);
    assert(struct_val(st,"Bar") == 28);
    assert(struct_val(st,"Baz") == 9);
    assert(struct_val(st,"Baz",5) == 9);
    assert(struct_val(st,"Qux") == undef);
    assert(struct_val(st,"Qux",5) == 5);
}
test_struct_val();


module test_struct_keys() {
    assert(struct_keys([["Foo",3],["Bar",2],["Baz",1]]) == ["Foo","Bar","Baz"]);
    assert(struct_keys([["Zee",1],["Why",2],["Exx",3]]) == ["Zee","Why","Exx"]);
}
test_struct_keys();


module test_struct_echo() {
    // Can't yet test echo output
}
test_struct_echo();


module test_is_struct() {
    assert(is_struct([["Foo",1],["Bar",2],["Baz",3]]));
    assert(!is_struct([["Foo"],["Bar"],["Baz"]]));
    assert(!is_struct(["Foo","Bar","Baz"]));
    assert(!is_struct([3,4,5]));
    assert(!is_struct(3));
    assert(!is_struct(true));
    assert(!is_struct("foo"));
}
test_is_struct();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
