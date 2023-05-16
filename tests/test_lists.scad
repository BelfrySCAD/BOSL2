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
    assert(slice(l,-10,-8) == []);
    assert(slice(l,10,12) == []);
    assert(slice(l,12,10) == []);
    assert(slice(l,4,12) == [7,8,9]);
    assert(slice(l,-10,2) == [3,4,5]);
    assert(slice(l,-10,-4) == [3,4,5,6]);
    assert(slice(l,-1,1) == []);
    assert(slice(l,5,4) == []);
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
    path = [[1,1],[-1,1],[-1,-1],[1,-1]];
    assert(list_rotate(path,1) == [[-1,1],[-1,-1],[1,-1],[1,1]]);
    assert(list_rotate(path,2) == [[-1,-1],[1,-1],[1,1],[-1,1]]);
}
test_list_rotate();



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
    assert_equal(list_set([1,2,3], 5,9,minlen=4), [1,2,3,0,0,9]);
    assert_equal(list_set([1,2,3], 5,9,minlen=7), [1,2,3,0,0,9,0]);
    assert_equal(list_set([1,2,3], 5,9,dflt=12), [1,2,3,12,12,9]);
    assert_equal(list_set([1,2,3], -1,12), [1,2,12]);
    assert_equal(list_set([1,2,3], -1,12,minlen=5), [1,2,12,0,0]);
    assert_equal(list_set([1,2,3], [-2,5], [8,9]), [1,8,3,0,0,9]);
    assert_equal(list_set([1,2,3], [-2,5], [8,9],minlen=8,dflt=-1), [1,8,3,-1,-1,9,-1,-1]);
    assert_equal(list_set([1,2,3], [-2,5], [8,9],minlen=3,dflt=-1), [1,8,3,-1,-1,9]);
    assert_equal(list_set([1,2,3], [0],[4], minlen=5), [4,2,3,0,0]);
    assert_equal(list_set([], 2,3), [0,0,3]);
    assert_equal(list_set([], 2,3,minlen=5,dflt=1), [1,1,3,1,1]);
}
test_list_set();


module test_list_remove() {
    assert(list_remove([3,6,9,12],1) == [3,9,12]);
    assert(list_remove([3,6,9,12],[1]) == [3,9,12]);
    assert(list_remove([3,6,9,12],[1,3]) == [3,9]);
    assert(list_remove([3,6,9],[]) == [3,6,9]);
    assert(list_remove([],[]) == []);
    assert(list_remove([1,2,3], -1)==[1,2,3]);
    assert(list_remove([1,2,3], 3)==[1,2,3]);    
    assert(list_remove([1,2,3], [-1,3])==[1,2,3]);    
    assert(list_remove([1,2,3], [-1,1,3])==[1,3]);    
}
test_list_remove();

module test_list_remove_values() {
    animals = ["bat", "cat", "rat", "dog", "bat", "rat"];
    assert(list_remove_values(animals, "rat") == ["bat","cat","dog","bat","rat"]);
    assert(list_remove_values(animals, "bat", all=true) == ["cat","rat","dog","rat"]);
    assert(list_remove_values(animals, ["bat","rat"]) == ["cat","dog","bat","rat"]);
    assert(list_remove_values(animals, ["bat","rat"], all=true) == ["cat","dog"]);
    assert(list_remove_values(animals, ["tucan","rat"], all=true) == ["bat","cat","dog","bat"]);

    test = [3,4,[5,6],7,5,[5,6],4,[6,5],7,[4,4]];
    assert_equal(list_remove_values(test,4), [3, [5, 6], 7, 5, [5, 6], 4, [6, 5], 7, [4, 4]]);
    assert_equal(list_remove_values(test,[4,4]), [3, [5, 6], 7, 5, [5, 6], [6, 5], 7, [4, 4]]);
    assert_equal(list_remove_values(test,[4,7]), [3, [5, 6], 5, [5, 6], 4, [6, 5], 7, [4, 4]]);
    assert_equal(list_remove_values(test,[5,6]), [3, 4, [5, 6], 7, [5, 6], 4, [6, 5], 7, [4, 4]]);
    assert_equal(list_remove_values(test,[[5,6]]), [3,4,7,5,[5,6],4,[6,5],7,[4,4]]);
    assert_equal(list_remove_values(test,[[5,6]],all=true), [3,4,7,5,4,[6,5],7,[4,4]]);    
    assert_equal(list_remove_values(test,4,all=true),  [3, [5, 6], 7, 5, [5, 6], [6, 5],7, [4, 4]]);
    assert_equal(list_remove_values(test,[4,7],all=true), [3, [5, 6], 5, [5, 6], [6, 5], [4, 4]]);
    assert_equal(list_remove_values(test,[]),test);
    assert_equal(list_remove_values(test,[],all=true),test);
    assert_equal(list_remove_values(test,99), test);
    assert_equal(list_remove_values(test,99,all=true), test);
    assert_equal(list_remove_values(test,[99,100],all=true), test);
    assert_equal(list_remove_values(test,[99,100]), test);            
}
test_list_remove_values();


module test_list_insert() {
    assert_equal(list_insert([3,6,9,12],1,5),[3,5,6,9,12]);
    assert_equal(list_insert([3,6,9,12],[1,3],[5,11]),[3,5,6,9,11,12]);
    assert_equal(list_insert([3],1,4), [3,4]);
    assert_equal(list_insert([3],[0,1], [1,2]), [1,3,2]);
    assert_equal(list_insert([1,2,3],[],[]),[1,2,3]);
    assert_equal(list_insert([], 0, 4),[4]);
    assert_equal(list_insert([1,2,3],-2,4), [1,4,2,3]);
    assert_equal(list_insert([1,2,3,4,5], [-1,-3],[12,9]), [1,2,9,3,4,12,5]);
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


module test_min_length() {
    assert(min_length(["foobar", "bazquxx", "abcd"]) == 4);
}
test_min_length();


module test_max_length() {
    assert(max_length(["foobar", "bazquxx", "abcd"]) == 7);
}
test_max_length();


module test_list_pad() {
    assert(list_pad([4,5,6], 5, 8) == [4,5,6,8,8]);
    assert(list_pad([4,5,6,7,8], 5, 8) == [4,5,6,7,8]);
    assert(list_pad([4,5,6,7,8,9], 5, 8) == [4,5,6,7,8,9]);
}
test_list_pad();


module test_idx() {
    colors = ["red", "green", "blue", "cyan"];
    assert([for (i=idx(colors)) i] == [0,1,2,3]);
    assert([for (i=idx(colors,e=-2)) i] == [0,1,2]);
    assert([for (i=idx(colors,s=1)) i] == [1,2,3]);
    assert([for (i=idx(colors,s=1,e=-2)) i] == [1,2]);
}
test_idx();


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
    assert_equal(pair([],wrap=true),[]);
    assert_equal(pair([],wrap=false),[]);
    assert_equal(pair([1],wrap=true),[]);
    assert_equal(pair([1],wrap=false),[]);
    assert_equal(pair([1,2],wrap=false),[[1,2]]);
    assert_equal(pair([1,2],wrap=true),[[1,2],[2,1]]);
}
test_pair();


module test_triplet() {
    assert(triplet([3,4,5,6,7]) == [[3,4,5], [4,5,6], [5,6,7]]);
    assert(triplet("ABCDE") == [["A","B","C"], ["B","C","D"], ["C","D","E"]]);
    assert(triplet([3,4,5,6],true) == [[6,3,4],[3,4,5], [4,5,6], [5,6,3]]);
    assert(triplet("ABCD",true) == [["D","A","B"],["A","B","C"], ["B","C","D"], ["C","D","A"]]);
    assert(triplet("ABCD",wrap=true) == [["D","A","B"],["A","B","C"], ["B","C","D"], ["C","D","A"]]);
    assert_equal(triplet([],wrap=true),[]);
    assert_equal(triplet([],wrap=false),[]);    
    assert_equal(triplet([1],wrap=true),[]);
    assert_equal(triplet([1],wrap=false),[]);    
    assert_equal(triplet([1,2],wrap=true),[]);
    assert_equal(triplet([1,2],wrap=false),[]);    
    assert_equal(triplet([1,2,3],wrap=true),[[3,1,2],[1,2,3],[2,3,1]]);
    assert_equal(triplet([1,2,3],wrap=false),[[1,2,3]]);    
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


module test_list_to_matrix() {
    v = [1,2,3,4,5,6];
    assert(list_to_matrix(v,2) == [[1,2], [3,4], [5,6]]);
    assert(list_to_matrix(v,3) == [[1,2,3], [4,5,6]]);
    assert(list_to_matrix(v,4,0) == [[1,2,3,4], [5,6,0,0]]);
}
test_list_to_matrix();


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


module test_list_shape() {
    assert(list_shape([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]]) == [2,2,3]);
    assert(list_shape([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]], 0) == 2);
    assert(list_shape([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]], 2) == 3);
    assert(list_shape([[[1,2,3],[4,5,6]],[[7,8,9]]]) == [2,undef,3]);
    assert(list_shape([1,2,3,4,5,6,7,8,9]) == [9]);
    assert(list_shape([[1],[2],[3],[4],[5],[6],[7],[8],[9]]) == [9,1]);
    assert(list_shape([]) == [0]);
    assert(list_shape([[]]) == [1,0]);
    assert(list_shape([[],[]]) == [2,0]);
    assert(list_shape([[],[1]]) == [2,undef]);
}
test_list_shape();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
