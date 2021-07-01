include <../std.scad>


// Section: List Query Operations

module test_is_homogeneous(){
    assert(is_homogeneous([[1,["a"]], [2,["b"]]])==true);
    assert(is_homogeneous([[1,["a"]], [2,[true]]])==false);
    assert(is_homogeneous([[1,["a"]], [2,[true]]],1)==true);
    assert(is_homogeneous([[1,["a"]], [2,[true]]],2)==false);
    assert(is_homogeneous([[1,["a"]], [true,["b"]]])==false);
}
test_is_homogeneous();


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


module test_slice() {
    l = [3,4,5,6,7,8,9];
    assert(slice(l, 5, 6) == [8,9]);
    assert(slice(l, 5, 8) == [8,9]);
    assert(slice(l, 5, 2) == []);
    assert(slice(l, -3, -1) == [7,8,9]);
    assert(slice(l, 3, 3) == [6]);
    assert(slice(l, 4) == [7,8,9]);
    assert(slice(l, -2) == [8,9]);
}
test_slice();


module test_last() {
    list = [1,2,3,4];
    assert(last(list)==4);
    assert(last([])==undef);
}
test_last();


module test_list_head() {
    list = [1,2,3,4];
    assert_equal(list_head(list), [1,2,3]);
    assert_equal(list_head([1]), []);
    assert_equal(list_head([]), []);
    assert_equal(list_head(list,-3), [1,2]);
    assert_equal(list_head(list,1), [1,2]);
    assert_equal(list_head(list,2), [1,2,3]);
    assert_equal(list_head(list,6), [1,2,3,4]);
    assert_equal(list_head(list,-6), []);
}
test_list_head();


module test_list_tail() {
    list = [1,2,3,4];
    assert_equal(list_tail(list), [2,3,4]);
    assert_equal(list_tail([1]), []);
    assert_equal(list_tail([]), []);
    assert_equal(list_tail(list,-3), [2,3,4]);
    assert_equal(list_tail(list,2), [3,4]);
    assert_equal(list_tail(list,3), [4]);
    assert_equal(list_tail(list,6), []);
    assert_equal(list_tail(list,-6), [1,2,3,4]);
}
test_list_tail();


module test_in_list() {
    assert(in_list("bar", ["foo", "bar", "baz"]));
    assert(!in_list("bee", ["foo", "bar", "baz"]));
    assert(in_list("bar", [[2,"foo"], [4,"bar"], [3,"baz"]], idx=1));
    assert(!in_list("bee", ["foo", "bar", ["bee"]]));
    assert(in_list(NAN, [NAN])==false);
    assert(!in_list(undef, [3,4,5]));
    assert(in_list(undef,[3,4,undef,5]));
    assert(!in_list(3,[]));
    assert(!in_list(3,[4,5,[3]]));
}
test_in_list();


module test_min_index() {
    assert(min_index([5,3,9,6,2,7,8,2,1])==8);
    assert(min_index([5,3,9,6,2,7,8,2,7],all=true)==[4,7]);
}
test_min_index();


module test_max_index() {
    assert(max_index([5,3,9,6,2,7,8,9,1])==2);
    assert(max_index([5,3,9,6,2,7,8,9,7],all=true)==[2,7]);
}
test_max_index();


module test_list_increasing() {
    assert(list_increasing([1,2,3,4]) == true);
    assert(list_increasing([1,3,2,4]) == false);
    assert(list_increasing([4,3,2,1]) == false);
}
test_list_increasing();


module test_list_decreasing() {
    assert(list_decreasing([1,2,3,4]) == false);
    assert(list_decreasing([4,2,3,1]) == false);
    assert(list_decreasing([4,3,2,1]) == true);
}
test_list_decreasing();


// Section: Basic List Generation

module test_repeat() {
    assert(repeat(1, 4) == [1,1,1,1]);
    assert(repeat(8, [2,3]) == [[8,8,8], [8,8,8]]);
    assert(repeat(0, [2,2,3]) == [[[0,0,0],[0,0,0]], [[0,0,0],[0,0,0]]]);
    assert(repeat([1,2,3],3) == [[1,2,3], [1,2,3], [1,2,3]]);
    assert(repeat(4, [2,-1]) == [[], []]);
}
test_repeat();


module test_count() {
    assert_equal(count(5), [0,1,2,3,4]);
    assert_equal(count(5,3), [3,4,5,6,7]);
    assert_equal(count(4,3,2), [3,5,7,9]);
    assert_equal(count(5,0,0.25), [0, 0.25, 0.5, 0.75, 1.0]);
}
test_count();


module test_reverse() {
    assert(reverse([3,4,5,6]) == [6,5,4,3]);
    assert(reverse("abcd") == "dcba");
    assert(reverse([]) == []);
}
test_reverse();


module test_list_rotate() {
    assert(list_rotate([1,2,3,4,5],-2) == [4,5,1,2,3]);
    assert(list_rotate([1,2,3,4,5],-1) == [5,1,2,3,4]);
    assert(list_rotate([1,2,3,4,5],0) == [1,2,3,4,5]);
    assert(list_rotate([1,2,3,4,5],1) == [2,3,4,5,1]);
    assert(list_rotate([1,2,3,4,5],2) == [3,4,5,1,2]);
    assert(list_rotate([1,2,3,4,5],3) == [4,5,1,2,3]);
    assert(list_rotate([1,2,3,4,5],4) == [5,1,2,3,4]);
    assert(list_rotate([1,2,3,4,5],5) == [1,2,3,4,5]);
    assert(list_rotate([1,2,3,4,5],6) == [2,3,4,5,1]);
    assert(list_rotate([],3) == []);
}
test_list_rotate();


module test_deduplicate() {
    assert_equal(deduplicate([8,3,4,4,4,8,2,3,3,8,8]), [8,3,4,8,2,3,8]);
    assert_equal(deduplicate(closed=true, [8,3,4,4,4,8,2,3,3,8,8]), [8,3,4,8,2,3]);
    assert_equal(deduplicate("Hello"), "Helo");
    assert_equal(deduplicate([[3,4],[7,1.99],[7,2],[1,4]],eps=0.1), [[3,4],[7,2],[1,4]]);
    assert_equal(deduplicate([], closed=true), []);
    assert_equal(deduplicate([[1,[1,[undef]]],[1,[1,[undef]]],[1,[2]],[1,[2,[0]]]]), [[1, [1,[undef]]],[1,[2]],[1,[2,[0]]]]);
}
test_deduplicate();


module test_deduplicate_indexed() {
    assert(deduplicate_indexed([8,6,4,6,3], [1,4,3,1,2,2,0,1]) == [1,4,1,2,0,1]);
    assert(deduplicate_indexed([8,6,4,6,3], [1,4,3,1,2,2,0,1], closed=true) == [1,4,1,2,0]);
}
test_deduplicate_indexed();


module test_list_set() {
    assert_equal(list_set([2,3,4,5], 2, 21), [2,3,21,5]);
    assert_equal(list_set([2,3,4,5], [1,3], [81,47]), [2,81,4,47]);
    assert_equal(list_set([2,3,4,5], [2], [21]), [2,3,21,5]);
    assert_equal(list_set([1,2,3], [], []), [1,2,3]);
    assert_equal(list_set([1,2,3], [1,5], [4,4]), [1,4,3,0,0,4]);
    assert_equal(list_set([1,2,3], [1,5], [4,4],dflt=12), [1,4,3,12,12,4]);
    assert_equal(list_set([1,2,3], [1,2], [4,4],dflt=12, minlen=5), [1,4,4,12,12]);
    assert_equal(list_set([1,2,3], 1, 4, dflt=12, minlen=5), [1,4,3,12,12]);
    assert_equal(list_set([1,2,3], [],[],dflt=12, minlen=5), [1,2,3,12,12]);
    assert_equal(list_set([1,2,3], 5,9), [1,2,3,0,0,9]);
    assert_equal(list_set([1,2,3], 5,9,dflt=12), [1,2,3,12,12,9]);    
}
test_list_set();


module test_list_remove() {
    assert(list_remove([3,6,9,12],1) == [3,9,12]);
    assert(list_remove([3,6,9,12],[1,3]) == [3,9]);
    assert(list_remove([3,6,9],[]) == [3,6,9]);
    assert(list_remove([],[]) == []);
}
test_list_remove();

module test_list_remove_values() {
    animals = ["bat", "cat", "rat", "dog", "bat", "rat"];
    assert(list_remove_values(animals, "rat") == ["bat","cat","dog","bat","rat"]);
    assert(list_remove_values(animals, "bat", all=true) == ["cat","rat","dog","rat"]);
    assert(list_remove_values(animals, ["bat","rat"]) == ["cat","dog","bat","rat"]);
    assert(list_remove_values(animals, ["bat","rat"], all=true) == ["cat","dog"]);
    assert(list_remove_values(animals, ["tucan","rat"], all=true) == ["bat","cat","dog","bat"]);
}
test_list_remove_values();


module test_list_insert() {
    assert_equal(list_insert([3,6,9,12],1,5),[3,5,6,9,12]);
    assert_equal(list_insert([3,6,9,12],[1,3],[5,11]),[3,5,6,9,11,12]);
    assert_equal(list_insert([3],1,4), [3,4]);
    assert_equal(list_insert([3],[0,1], [1,2]), [1,3,2]);
    assert_equal(list_insert([1,2,3],[],[]),[1,2,3]);
    assert_equal(list_insert([], 0, 4),[4]);
}
test_list_insert();


module test_bselect() {
    assert(bselect([3,4,5,6,7], [false,false,false,false,false]) == []);
    assert(bselect([3,4,5,6,7], [false,true,true,false,true]) == [4,5,7]);
    assert(bselect([3,4,5,6,7], [true,true,true,true,true]) == [3,4,5,6,7]);
}
test_bselect();


module test_list_bset() {
    assert(list_bset([false,true,false,true,false], [3,4]) == [0,3,0,4,0]);
    assert(list_bset([false,true,false,true,false], [3,4], dflt=1) == [1,3,1,4,1]);
}
test_list_bset();


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


module test_idx() {
    colors = ["red", "green", "blue", "cyan"];
    assert([for (i=idx(colors)) i] == [0,1,2,3]);
    assert([for (i=idx(colors,e=-2)) i] == [0,1,2]);
    assert([for (i=idx(colors,s=1)) i] == [1,2,3]);
    assert([for (i=idx(colors,s=1,e=-2)) i] == [1,2]);
}
test_idx();


module test_enumerate() {
    assert(enumerate(["a","b","c"]) == [[0,"a"], [1,"b"], [2,"c"]]);
    assert(enumerate([[88,"a"],[76,"b"],[21,"c"]], idx=1) == [[0,"a"], [1,"b"], [2,"c"]]);
    assert(enumerate([["cat","a",12],["dog","b",10],["log","c",14]], idx=[1:2]) == [[0,"a",12], [1,"b",10], [2,"c",14]]);
}
test_enumerate();


module test_shuffle() {
    nums1 = count(100);
    nums2 = shuffle(nums1,33);
    nums3 = shuffle(nums2,99);
    assert(sort(nums2)==nums1);
    assert(sort(nums3)==nums1);
    assert(nums1!=nums2);
    assert(nums2!=nums3);
    assert(nums1!=nums3);
    str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    shufstr = shuffle(str,12);
    assert(shufstr != str && sort(shufstr)==str);
}
test_shuffle();


module test_sort() {
    assert(sort([7,3,9,4,3,1,8]) == [1,3,3,4,7,8,9]);
    assert(sort([[4,0],[7],[3,9],20,[4],[3,1],[8]]) == [20,[3,1],[3,9],[4],[4,0],[7],[8]]);
    assert(sort([[4,0],[7],[3,9],20,[4],[3,1],[8]],idx=1) == [[7],20,[4],[8],[4,0],[3,1],[3,9]]);
    assert(sort([[8,6],[3,1],[9,2],[4,3],[3,4],[1,5],[8,0]]) == [[1,5],[3,1],[3,4],[4,3],[8,0],[8,6],[9,2]]);
    assert(sort([[8,0],[3,1],[9,2],[4,3],[3,4],[1,5],[8,6]],idx=1) == [[8,0],[3,1],[9,2],[4,3],[3,4],[1,5],[8,6]]);
    assert(sort(["cat", "oat", "sat", "bat", "vat", "rat", "pat", "mat", "fat", "hat", "eat"]) 
           == ["bat", "cat", "eat", "fat", "hat", "mat", "oat", "pat", "rat", "sat", "vat"]);
    assert(sort(enumerate([[2,3,4],[1,2,3],[2,4,3]]),idx=1)==[[1,[1,2,3]], [0,[2,3,4]], [2,[2,4,3]]]);
    assert(sort([0,"1",[1,0],2,"a",[1]])== [0,2,"1","a",[1],[1,0]]);
    assert(sort([["oat",0], ["cat",1], ["bat",3], ["bat",2], ["fat",3]])==  [["bat",2],["bat",3],["cat",1],["fat",3],["oat",0]]);
}
test_sort();


module test_sortidx() {
    lst1 = ["da","bax","eaw","cav"];
    assert(sortidx(lst1) == [1,3,0,2]);
    lst5 = [3,5,1,7];
    assert(sortidx(lst5) == [2,0,1,3]);
    lst2 = [
        ["foo", 88, [0,0,1], false],
        ["bar", 90, [0,1,0], true],
        ["baz", 89, [1,0,0], false],
        ["qux", 23, [1,1,1], true]
    ];
    assert(sortidx(lst2, idx=1) == [3,0,2,1]);
    assert(sortidx(lst2, idx=0) == [1,2,0,3]);
    assert(sortidx(lst2, idx=[1,3]) == [3,0,2,1]);
    lst3 = [[-4,0,0],[0,0,-4],[0,-4,0],[-4,0,0],[0,-4,0],[0,0,4],
            [0,0,-4],[0,4,0],[4,0,0],[0,0,4],[0,4,0],[4,0,0]];
    assert(sortidx(lst3)==[0,3,2,4,1,6,5,9,7,10,8,11]);
    assert(sortidx([[4,0],[7],[3,9],20,[4],[3,1],[8]]) == [3,5,2,4,0,1,6]);
    assert(sortidx([[4,0],[7],[3,9],20,[4],[3,1],[8]],idx=1) ==  [1,3,4,6,0,5,2]);
    lst4=[0,"1",[1,0],2,"a",[1]];
    assert(sortidx(lst4)== [0,3,1,4,5,2]);
    assert(sortidx(["cat","oat","sat","bat","vat","rat","pat","mat","fat","hat","eat"]) 
             == [3,0,10,8,9,7,1,6,5,2,4]);
    assert(sortidx([["oat",0], ["cat",1], ["bat",3], ["bat",2], ["fat",3]])==  [3,2,1,4,0]);
    assert(sortidx(["Belfry", "OpenScad", "Library", "Documentation"])==[0,3,2,1]);
    assert(sortidx(["x",1,[],0,"abc",true])==[5,3,1,4,0,2]);
}
test_sortidx();

module test_group_sort() {
    assert_equal(group_sort([]), [[]]);
    assert_equal(group_sort([8]), [[8]]);
    assert_equal(group_sort([7,3,9,4,3,1,8]), [[1], [3, 3], [4], [7], [8], [9]]);
    assert_equal(group_sort([[5,"a"],[2,"b"], [5,"c"], [3,"d"], [2,"e"] ], idx=0), [[[2, "b"], [2, "e"]], [[3, "d"]], [[5, "a"], [5, "c"]]]);
    assert_equal(group_sort([["a",5],["b",6], ["c",1], ["d",2], ["e",6] ], idx=1), [[["c", 1]], [["d", 2]], [["a", 5]], [["b", 6], ["e", 6]]] );
}
test_group_sort();


module test_unique() {
    assert_equal(unique([]), []);
    assert_equal(unique([8]), [8]);
    assert_equal(unique([7,3,9,4,3,1,8]), [1,3,4,7,8,9]);
    assert_equal(unique(["A","B","R","A","C","A","D","A","B","R","A"]), ["A", "B", "C", "D", "R"]);
}
test_unique();


module test_unique_count() {
    assert_equal(
        unique_count([3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3,2,3,6]),
        [[1,2,3,4,5,6,7,8,9],[2,2,4,1,3,2,1,1,3]]
    );
    assert_equal(
        unique_count(["A","B","R","A","C","A","D","A","B","R","A"]),
        [["A","B","C","D","R"],[5,2,1,1,2]]
    );
}
test_unique_count();



// Sets

module test_set_union() {
    assert_equal(
        set_union([2,3,5,7,11], [1,2,3,5,8]),
        [2,3,5,7,11,1,8]
    );
    assert_equal(
        set_union([2,3,5,7,11], [1,2,3,5,8], get_indices=true),
        [[5,0,1,2,6],[2,3,5,7,11,1,8]]
    );
}
test_set_union();


module test_set_difference() {
    assert_equal(
        set_difference([2,3,5,7,11], [1,2,3,5,8]),
        [7,11]
    );
}
test_set_difference();


module test_set_intersection() {
    assert_equal(
        set_intersection([2,3,5,7,11], [1,2,3,5,8]),
        [2,3,5]
    );
}
test_set_intersection();


// Arrays

module test_add_scalar() {
    assert(add_scalar([1,2,3],3) == [4,5,6]);
    assert(add_scalar([[1,2,3],[3,4,5]],3) == [[4,5,6],[6,7,8]]);
}
test_add_scalar();


module test_subindex() {
    v = [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]];
    assert(subindex(v,2) == [3, 7, 11, 15]);
    assert(subindex(v,[2]) == [[3], [7], [11], [15]]);
    assert(subindex(v,[2,1]) == [[3, 2], [7, 6], [11, 10], [15, 14]]);
    assert(subindex(v,[1:3]) == [[2, 3, 4], [6, 7, 8], [10, 11, 12], [14, 15, 16]]);
}
test_subindex();


// Need decision about behavior for out of bounds ranges, empty ranges
module test_submatrix(){
  M = [[1,2,3,4,5],
       [6,7,8,9,10],
       [11,12,13,14,15],
       [16,17,18,19,20],
       [21,22,23,24,25]];
  assert_equal(submatrix(M,[1:2], [3:4]), [[9,10],[14,15]]);
  assert_equal(submatrix(M,[1], [3,4]), [[9,10]]);
  assert_equal(submatrix(M,1, [3,4]), [[9,10]]);
  assert_equal(submatrix(M, [3,4],1), [[17],[22]]);
  assert_equal(submatrix(M, [1,3],[2,4]), [[8,10],[18,20]]);
  assert_equal(submatrix(M, 1,3), [[9]]);
  A = [[true,    17, "test"],
     [[4,2],   91, false],
     [6,    [3,4], undef]];
  assert_equal(submatrix(A,[0,2],[1,2]),[[17, "test"], [[3, 4], undef]]);
}
test_submatrix();


module test_force_list() {
    assert_equal(force_list([3,4,5]), [3,4,5]);
    assert_equal(force_list(5), [5]);
    assert_equal(force_list(7, n=3), [7,7,7]);
    assert_equal(force_list(4, n=3, fill=1), [4,1,1]);
}
test_force_list();


module test_pair() {
    assert(pair([3,4,5,6]) == [[3,4], [4,5], [5,6]]);
    assert(pair("ABCD") == [["A","B"], ["B","C"], ["C","D"]]);
    assert(pair([3,4,5,6],true) == [[3,4], [4,5], [5,6], [6,3]]);
    assert(pair("ABCD",true) == [["A","B"], ["B","C"], ["C","D"], ["D","A"]]);
    assert(pair([3,4,5,6],wrap=true) == [[3,4], [4,5], [5,6], [6,3]]);
    assert(pair("ABCD",wrap=true) == [["A","B"], ["B","C"], ["C","D"], ["D","A"]]);
}
test_pair();


module test_triplet() {
    assert(triplet([3,4,5,6,7]) == [[3,4,5], [4,5,6], [5,6,7]]);
    assert(triplet("ABCDE") == [["A","B","C"], ["B","C","D"], ["C","D","E"]]);
    assert(triplet([3,4,5,6],true) == [[3,4,5], [4,5,6], [5,6,3], [6,3,4]]);
    assert(triplet("ABCD",true) == [["A","B","C"], ["B","C","D"], ["C","D","A"], ["D","A","B"]]);
    assert(triplet([3,4,5,6],wrap=true) == [[3,4,5], [4,5,6], [5,6,3], [6,3,4]]);
    assert(triplet("ABCD",wrap=true) == [["A","B","C"], ["B","C","D"], ["C","D","A"], ["D","A","B"]]);
}
test_triplet();


module test_combinations() {
    assert(combinations([3,4,5,6]) ==  [[3,4],[3,5],[3,6],[4,5],[4,6],[5,6]]);
    assert(combinations([3,4,5,6],n=3) == [[3,4,5],[3,4,6],[3,5,6],[4,5,6]]);
}
test_combinations();


module test_repeat_entries() {
    list = [0,1,2,3];
    assert(repeat_entries(list, 6) == [0,0,1,2,2,3]);
    assert(repeat_entries(list, 6, exact=false) == [0,0,1,1,2,2,3,3]);
    assert(repeat_entries(list, [1,1,2,1], exact=false) == [0,1,2,2,3]);
}
test_repeat_entries();


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
//test_zip();

module test_hstack() {
    M = ident(3);
    v1 = [2,3,4];
    v2 = [5,6,7];
    v3 = [8,9,10];
    a = hstack(v1,v2);   
    b = hstack(v1,v2,v3);
    c = hstack([M,v1,M]);
    d = hstack(subindex(M,0), subindex(M,[1, 2]));
    assert_equal(a,[[2, 5], [3, 6], [4, 7]]);
    assert_equal(b,[[2, 5, 8], [3, 6, 9], [4, 7, 10]]);
    assert_equal(c,[[1, 0, 0, 2, 1, 0, 0], [0, 1, 0, 3, 0, 1, 0], [0, 0, 1, 4, 0, 0, 1]]);
    assert_equal(d,M);
    strmat = [["three","four"], ["five","six"]];
    assert_equal(hstack(strmat,strmat), [["three", "four", "three", "four"], ["five", "six", "five", "six"]]);
    strvec = ["one","two"];
    assert_equal(hstack(strvec,strmat),[["o", "n", "e", "three", "four"], ["t", "w", "o", "five", "six"]]);
}
test_hstack();


module test_block_matrix() {
    A = [[1,2],[3,4]];
    B = ident(2);
    assert_equal(block_matrix([[A,B],[B,A],[A,B]]), [[1,2,1,0],[3,4,0,1],[1,0,1,2],[0,1,3,4],[1,2,1,0],[3,4,0,1]]);
    assert_equal(block_matrix([[A,B],ident(4)]), [[1,2,1,0],[3,4,0,1],[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    text = [["aa","bb"],["cc","dd"]];
    assert_equal(block_matrix([[text,B]]), [["aa","bb",1,0],["cc","dd",0,1]]);
}
test_block_matrix();


module test_diagonal_matrix() {
    assert_equal(diagonal_matrix([1,2,3]), [[1,0,0],[0,2,0],[0,0,3]]);
    assert_equal(diagonal_matrix([1,"c",2]), [[1,0,0],[0,"c",0],[0,0,2]]);
    assert_equal(diagonal_matrix([1,"c",2],"X"), [[1,"X","X"],["X","c","X"],["X","X",2]]);
    assert_equal(diagonal_matrix([[1,1],[2,2],[3,3]], [0,0]), [[ [1,1],[0,0],[0,0]], [[0,0],[2,2],[0,0]], [[0,0],[0,0],[3,3]]]);
}
test_diagonal_matrix();

module test_submatrix_set() {
    test = [[1,2,3,4,5],[6,7,8,9,10],[11,12,13,14,15], [16,17,18,19,20]];
    ragged = [[1,2,3,4,5],[6,7,8,9,10],[11,12], [16,17]];
    assert_equal(submatrix_set(test,[[9,8],[7,6]]), [[9,8,3,4,5],[7,6,8,9,10],[11,12,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,7],[8,6]],1),[[1,2,3,4,5],[9,7,8,9,10],[8,6,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,8],[7,6]],n=1), [[1,9,8,4,5],[6,7,6,9,10],[11,12,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,8],[7,6]],1,2), [[1,2,3,4,5],[6,7,9,8,10],[11,12,7,6,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,8],[7,6]],-1,-1), [[6,2,3,4,5],[6,7,8,9,10],[11,12,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,8],[7,6]],n=4), [[1,2,3,4,9],[6,7,8,9,7],[11,12,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(test,[[9,8],[7,6]],7,7), [[1,2,3,4,5],[6,7,8,9,10],[11,12,13,14,15], [16,17,18,19,20]]);
    assert_equal(submatrix_set(ragged, [["a","b"],["c","d"]], 1, 1), [[1,2,3,4,5],[6,"a","b",9,10],[11,"c"], [16,17]]);
    assert_equal(submatrix_set(test, [[]]), test);
}
test_submatrix_set();


module test_array_group() {
    v = [1,2,3,4,5,6];
    assert(array_group(v,2) == [[1,2], [3,4], [5,6]]);
    assert(array_group(v,3) == [[1,2,3], [4,5,6]]);
    assert(array_group(v,4,0) == [[1,2,3,4], [5,6,0,0]]);
}
test_array_group();


module test_group_data() {
    assert_equal(group_data([1,2,0], ["A","B","C"]), [["C"],["A"],["B"]]);
    assert_equal(group_data([1,3,0], ["A","B","C"]), [["C"],["A"],[],["B"]]);
    assert_equal(group_data([5,3,1], ["A","B","C"]), [[],["C"],[],["B"],[],["A"]]);
    assert_equal(group_data([1,3,1], ["A","B","C"]), [[],["A","C"],[],["B"]]);
}
test_group_data();


module test_flatten() {
    assert(flatten([[1,2,3], [4,5,[6,7,8]]]) == [1,2,3,4,5,[6,7,8]]);
    assert(flatten([]) == []);
}
test_flatten();


module test_full_flatten() {
    assert(full_flatten([[1,2,3], [4,5,[6,[7],8]]]) == [1,2,3,4,5,6,7,8]);
    assert(full_flatten([]) == []);
}
test_full_flatten();


module test_array_dim() {
    assert(array_dim([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]]) == [2,2,3]);
    assert(array_dim([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]], 0) == 2);
    assert(array_dim([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]], 2) == 3);
    assert(array_dim([[[1,2,3],[4,5,6]],[[7,8,9]]]) == [2,undef,3]);
    assert(array_dim([1,2,3,4,5,6,7,8,9]) == [9]);
    assert(array_dim([[1],[2],[3],[4],[5],[6],[7],[8],[9]]) == [9,1]);
    assert(array_dim([]) == [0]);
    assert(array_dim([[]]) == [1,0]);
    assert(array_dim([[],[]]) == [2,0]);
    assert(array_dim([[],[1]]) == [2,undef]);
}
test_array_dim();


module test_transpose() {
    assert(transpose([[1,2,3],[4,5,6],[7,8,9]]) == [[1,4,7],[2,5,8],[3,6,9]]);
    assert(transpose([[1,2,3],[4,5,6]]) == [[1,4],[2,5],[3,6]]);
    assert(transpose([[1,2,3],[4,5,6]],reverse=true) == [[6,3], [5,2], [4,1]]);
    assert(transpose([3,4,5]) == [3,4,5]);
}
test_transpose();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
