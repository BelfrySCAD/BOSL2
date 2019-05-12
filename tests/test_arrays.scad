include <BOSL2/std.scad>


// List/Array Ops

module test_replist() {
	assert(replist(1, 4) == [1,1,1,1]);
	assert(replist(8, [2,3]) == [[8,8,8], [8,8,8]]);
	assert(replist(0, [2,2,3]) == [[[0,0,0],[0,0,0]], [[0,0,0],[0,0,0]]]);
	assert(replist([1,2,3],3) == [[1,2,3], [1,2,3], [1,2,3]]);
}
test_replist();


module test_in_list() {
	assert(in_list("bar", ["foo", "bar", "baz"]));
	assert(!in_list("bee", ["foo", "bar", "baz"]));
	assert(in_list("bar", [[2,"foo"], [4,"bar"], [3,"baz"]], idx=1));
}
test_in_list();


module test_slice() {
	assert(slice([3,4,5,6,7,8,9], 3, 5) == [6,7]);
	assert(slice([3,4,5,6,7,8,9], 2, -1) == [5,6,7,8,9]);
	assert(slice([3,4,5,6,7,8,9], 1, 1) == []);
	assert(slice([3,4,5,6,7,8,9], 6, -1) == [9]);
	assert(slice([3,4,5,6,7,8,9], 2, -2) == [5,6,7,8]);
}
test_slice();


module test_select() {
	l = [3,4,5,6,7,8,9];
	assert(select(l, 5, 6) == [8,9]);
	assert(select(l, 5, 8) == [8,9,3,4]);
	assert(select(l, 5, 2) == [8,9,3,4,5]);
	assert(select(l, -3, -1) == [7,8,9]);
	assert(select(l, 3, 3) == [6]);
	assert(select(l, 4) == 7);
	assert(select(l, -2) == 8);
	assert(select(l, [1:3]) == [4,5,6]);
	assert(select(l, [1,3]) == [4,6]);
}
test_select();


module test_list_range() {
	assert(list_range(4) == [0,1,2,3]);
	assert(list_range(n=4, step=2) == [0,2,4,6]);
	assert(list_range(n=4, s=3, step=3) == [3,6,9,12]);
	assert(list_range(n=4, s=3, e=9, step=3) == [3,6,9]);
	assert(list_range(e=3) == [0,1,2,3]);
	assert(list_range(e=6, step=2) == [0,2,4,6]);
	assert(list_range(s=3, e=5) == [3,4,5]);
	assert(list_range(s=3, e=8, step=2) == [3,5,7]);
	assert(list_range(s=4, e=8, step=2) == [4,6,8]);
	assert(list_range(n=4, s=[3,4], step=[2,3]) == [[3,4], [5,7], [7,10], [9,13]]);
}
test_list_range();


module test_reverse() {
	assert(reverse([3,4,5,6]) == [6,5,4,3]);
}
test_reverse();


// TODO: list_remove()
// TODO: list_insert()


module test_list_shortest() {
	assert(list_shortest(["foobar", "bazquxx", "abcd"]) == 4);
}
test_list_shortest();


module test_list_longest() {
	assert(list_longest(["foobar", "bazquxx", "abcd"]) == 7);
}
test_list_longest();


module test_list_pad() {
	assert(list_pad([4,5,6], 5, 8) == [4,5,6,8,8]);
	assert(list_pad([4,5,6,7,8], 5, 8) == [4,5,6,7,8]);
	assert(list_pad([4,5,6,7,8,9], 5, 8) == [4,5,6,7,8,9]);
}
test_list_pad();


module test_list_trim() {
	assert(list_trim([4,5,6], 5) == [4,5,6]);
	assert(list_trim([4,5,6,7,8], 5) == [4,5,6,7,8]);
	assert(list_trim([3,4,5,6,7,8,9], 5) == [3,4,5,6,7]);
}
test_list_trim();


module test_list_fit() {
	assert(list_fit([4,5,6], 5, 8) == [4,5,6,8,8]);
	assert(list_fit([4,5,6,7,8], 5, 8) == [4,5,6,7,8]);
	assert(list_fit([3,4,5,6,7,8,9], 5, 8) == [3,4,5,6,7]);
}
test_list_fit();


module test_enumerate() {
	assert(enumerate(["a","b","c"]) == [[0,"a"], [1,"b"], [2,"c"]]);
	assert(enumerate([[88,"a"],[76,"b"],[21,"c"]], idx=1) == [[0,"a"], [1,"b"], [2,"c"]]);
	assert(enumerate([["cat","a",12],["dog","b",10],["log","c",14]], idx=[1:2]) == [[0,"a",12], [1,"b",10], [2,"c",14]]);
}
test_enumerate();


module test_sort() {
	assert(sort([7,3,9,4,3,1,8]) == [1,3,3,4,7,8,9]);
	assert(sort(["cat", "oat", "sat", "bat", "vat", "rat", "pat", "mat", "fat", "hat", "eat"]) == ["bat", "cat", "eat", "fat", "hat", "mat", "oat", "pat", "rat", "sat", "vat"]);
	assert(sort(enumerate([[2,3,4],[1,2,3],[2,4,3]]),idx=1)==[[1,[1,2,3]], [0,[2,3,4]], [2,[2,4,3]]]);
}
test_sort();


module test_sortidx() {
	lst1 = ["d","b","e","c"];
	assert(sortidx(lst1) == [1,3,0,2]);
	lst2 = [
		["foo", 88, [0,0,1], false],
		["bar", 90, [0,1,0], true],
		["baz", 89, [1,0,0], false],
		["qux", 23, [1,1,1], true]
	];
	assert(sortidx(lst2, idx=1) == [3,0,2,1]);
	assert(sortidx(lst2, idx=0) == [1,2,0,3]);
	assert(sortidx(lst2, idx=[1,3]) == [3,0,2,1]);
	lst3 = [[-4, 0, 0], [0, 0, -4], [0, -4, 0], [-4, 0, 0], [0, -4, 0], [0, 0, 4], [0, 0, -4], [0, 4, 0], [4, 0, 0], [0, 0, 4], [0, 4, 0], [4, 0, 0]];
	assert(sortidx(lst3)==[0,3,2,4,1,6,5,9,7,10,8,11]);
}
test_sortidx();


module test_unique() {
	assert(unique([]) == []);
	assert(unique([8]) == [8]);
	assert(unique([7,3,9,4,3,1,8]) == [1,3,4,7,8,9]);
}
test_unique();


// Arrays


module test_subindex() {
	v = [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]];
	assert(subindex(v,2) == [3, 7, 11, 15]);
	assert(subindex(v,[2,1]) == [[3, 2], [7, 6], [11, 10], [15, 14]]);
	assert(subindex(v,[1:3]) == [[2, 3, 4], [6, 7, 8], [10, 11, 12], [14, 15, 16]]);
}
test_subindex();


module test_pair() {
	assert(pair([3,4,5,6]) == [[3,4], [4,5], [5,6]]);
	assert(pair("ABCD") == [["A","B"], ["B","C"], ["C","D"]]);
}
test_pair();


module test_pair_wrap() {
	assert(pair_wrap([3,4,5,6]) == [[3,4], [4,5], [5,6], [6,3]]);
	assert(pair_wrap("ABCD") == [["A","B"], ["B","C"], ["C","D"], ["D","A"]]);
}
test_pair_wrap();


module test_zip() {
	v1 = [1,2,3,4];
	v2 = [5,6,7];
	v3 = [8,9,10,11];
	assert(zip(v1,v3) == [[1,8],[2,9],[3,10],[4,11]]);
	assert(zip([v1,v3]) == [[1,8],[2,9],[3,10],[4,11]]);
	assert(zip([v1,v2],fit="short") == [[1,5],[2,6],[3,7]]);
	assert(zip([v1,v2],fit="long") == [[1,5],[2,6],[3,7],[4,undef]]);
	assert(zip([v1,v2],fit="long", fill=0) == [[1,5],[2,6],[3,7],[4,0]]);
	assert(zip([v1,v2,v3],fit="long") == [[1,5,8],[2,6,9],[3,7,10],[4,undef,11]]);
}
test_zip();


module test_array_group() {
	v = [1,2,3,4,5,6];
	assert(array_group(v,2) == [[1,2], [3,4], [5,6]]);
	assert(array_group(v,3) == [[1,2,3], [4,5,6]]);
	assert(array_group(v,4,0) == [[1,2,3,4], [5,6,0,0]]);
}
test_array_group();


module test_flatten() {
	assert(flatten([[1,2,3], [4,5,[6,7,8]]]) == [1,2,3,4,5,[6,7,8]]);
}
test_flatten();


module test_array_dim() {
	assert(array_dim([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]]) == [2,2,3]);
	assert(array_dim([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]], 0) == 2);
	assert(array_dim([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]], 2) == 3);
	assert(array_dim([[[1,2,3],[4,5,6]],[[7,8,9]]]) == [2,undef,3]);
}
test_array_dim();


module test_transpose() {
	assert(transpose([[1,2,3],[4,5,6],[7,8,9]]) == [[1,4,7],[2,5,8],[3,6,9]]);
	assert(transpose([[1,2,3],[4,5,6]]) == [[1,4],[2,5],[3,6]]);
	assert(transpose([3,4,5]) == [3,4,5]);
}
test_transpose();



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
