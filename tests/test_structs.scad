include <../std.scad>
include <../structs.scad>


module test_struct_set() {
    st = struct_set([], "Foo", 42);
    assert(st == [["Foo",42]]);
    st2 = struct_set(st, "Bar", 28);
    assert(st2 == [["Foo",42],["Bar",28]]);
    st3 = struct_set(st2, "Foo", 91);
    assert(st3 == [["Bar",28],["Foo",91]]);
    st4 = struct_set(st3, [3,4,5,6]);
    assert(st4 == [["Bar", 28],["Foo",91],[3,4],[5,6]]);
    st5 = struct_set(st3, [[3,4],[5,6]]);
    assert(st5 == [["Bar", 28],["Foo",91],[[3,4],[5,6]]]);
    st6 = struct_set(st3, [3,4],true);
    assert(st6 == [["Bar", 28],["Foo",91],[[3,4],true]]);
    st7 = struct_set(st3, [3,4,[5,7],99]);
    assert(st7 == [["Bar", 28],["Foo",91],[3,4],[[5,7],99]]);
    st8 = struct_set(st3,[]);
    assert(st8==st3);
}
test_struct_set();


module test_struct_remove() {
    st = [["Foo",91],["Bar",28],["Baz",9]];
    assert(struct_remove(st, "Foo") == [["Bar",28],["Baz",9]]);
    assert(struct_remove(st, "Bar") == [["Foo",91],["Baz",9]]);
    assert(struct_remove(st, "Baz") == [["Foo",91],["Bar",28]]);
    assert(struct_remove(st, ["Baz","Baz"]) == [["Foo",91],["Bar",28]]);
    assert(struct_remove(st, ["Baz","Foo"]) == [["Bar",28]]);
    assert(struct_remove(st, []) == st);
    assert(struct_remove(st, ["Bar","niggle"]) == [["Foo",91],["Baz",9]]);
    assert(struct_remove(st, struct_keys(st)) == []);
}
test_struct_remove();


module test_struct_val() {
    st = [["Foo",91],["Bar",28],[true,99],["Baz",9],[[5,4],3], [7,92]];
    assert(struct_val(st,"Foo") == 91);
    assert(struct_val(st,"Bar") == 28);
    assert(struct_val(st,"Baz") == 9);
    assert(struct_val(st,"Baz",5) == 9);
    assert(struct_val(st,"Qux") == undef);
    assert(struct_val(st,"Qux",5) == 5);
    assert(struct_val(st,[5,4])==3);
    assert(struct_val(st,true)==99);
    assert(struct_val(st,5) == undef);
    assert(struct_val(st,7) == 92);
}
test_struct_val();


module test_struct_keys() {
    assert(struct_keys([["Foo",3],["Bar",2],["Baz",1]]) == ["Foo","Bar","Baz"]);
    assert(struct_keys([["Zee",1],["Why",2],["Exx",3]]) == ["Zee","Why","Exx"]);
    assert(struct_keys([["Zee",1],[[3,4],2],["Why",2],[9,1],["Exx",3]]) == ["Zee",[3,4],"Why",9,"Exx"]);    
}
test_struct_keys();


module test_echo_struct() {
    // Can't yet test echo output
}
test_echo_struct();


module test_is_struct() {
    assert(is_struct([["Foo",1],["Bar",2],["Baz",3]]));
    assert(!is_struct([["Foo"],["Bar"],["Baz"]]));
    assert(!is_struct(["Foo","Bar","Baz"]));
    assert(!is_struct([3,4,5]));
    assert(!is_struct(3));
    assert(!is_struct(true));
    assert(!is_struct("foo"));
    assert(is_struct([]));
}
test_is_struct();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
