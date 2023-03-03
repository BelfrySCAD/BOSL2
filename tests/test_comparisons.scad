include<../std.scad>

module test_sort() {
    assert(sort([7,3,9,4,3,1,8]) == [1,3,3,4,7,8,9]);
    assert(sort([[4,0],[7],[3,9],20,[4],[3,1],[8]]) == [20,[3,1],[3,9],[4],[4,0],[7],[8]]);
    assert(sort([[4,0],[7],[3,9],20,[4],[3,1],[8]],idx=1) == [[7],20,[4],[8],[4,0],[3,1],[3,9]]);
    assert(sort([[8,6],[3,1],[9,2],[4,3],[3,4],[1,5],[8,0]]) == [[1,5],[3,1],[3,4],[4,3],[8,0],[8,6],[9,2]]);
    assert(sort([[8,0],[3,1],[9,2],[4,3],[3,4],[1,5],[8,6]],idx=1) == [[8,0],[3,1],[9,2],[4,3],[3,4],[1,5],[8,6]]);
    assert(sort(["cat", "oat", "sat", "bat", "vat", "rat", "pat", "mat", "fat", "hat", "eat"]) 
           == ["bat", "cat", "eat", "fat", "hat", "mat", "oat", "pat", "rat", "sat", "vat"]);
    assert(sort([[0,[2,3,4]],[1,[1,2,3]],[2,[2,4,3]]],idx=1)==[[1,[1,2,3]], [0,[2,3,4]], [2,[2,4,3]]]);
    assert(sort([0,"1",[1,0],2,"a",[1]])== [0,2,"1","a",[1],[1,0]]);
    assert(sort([["oat",0], ["cat",1], ["bat",3], ["bat",2], ["fat",3]])==  [["bat",2],["bat",3],["cat",1],["fat",3],["oat",0]]);
}
test_sort();


module test_sortidx() {
    assert(sortidx([3]) == [0]);
    assert(sortidx([]) == []);
    assert(sortidx([[5,6,7]])==[0]);
    assert(sortidx(["abc"]) == [0]);
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




module test_list_wrap() {
    assert(list_wrap([[1,2,3],[4,5,6],[1,8,9]]) == [[1,2,3],[4,5,6],[1,8,9],[1,2,3]]);
    assert(list_wrap([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]) == [[1,2,3],[4,5,6],[1,8,9],[1,2,3]]);
    assert(list_wrap([])==[]);
    assert(list_wrap([3])==[3]);
}
test_list_wrap();


module test_list_unwrap() {
    assert(list_unwrap([[1,2,3],[4,5,6],[1,8,9]]) == [[1,2,3],[4,5,6],[1,8,9]]);
    assert(list_unwrap([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]) == [[1,2,3],[4,5,6],[1,8,9]]);
    assert(list_unwrap([])==[]);
    assert(list_unwrap([3])==[3]);
}
test_list_unwrap();



module test_is_increasing() {
    assert(is_increasing([1,2,3,4]) == true);
    assert(is_increasing([1,2,2,2]) == true);
    assert(is_increasing([1,3,2,4]) == false);
    assert(is_increasing([4,3,2,1]) == false);
    assert(is_increasing([1,2,3,4],strict=true) == true);
    assert(is_increasing([1,2,2,2],strict=true) == false);
    assert(is_increasing([1,3,2,4],strict=true) == false);
    assert(is_increasing([4,3,2,1],strict=true) == false);
    assert(is_increasing(["AB","BC","DF"]) == true);
    assert(is_increasing(["AB","DC","CF"]) == false);    
    assert(is_increasing([[1,2],[1,4],[2,3],[2,2]])==false);
    assert(is_increasing([[1,2],[1,4],[2,3],[2,3]])==true);
    assert(is_increasing([[1,2],[1,4],[2,3],[2,3]],strict=true)==false);
    assert(is_increasing("ABCFZ")==true);
    assert(is_increasing("ZYWRA")==false);    
}
test_is_increasing();


module test_is_decreasing() {
    assert(is_decreasing([1,2,3,4]) == false);
    assert(is_decreasing([4,2,3,1]) == false);
    assert(is_decreasing([4,2,2,1]) == true);
    assert(is_decreasing([4,3,2,1]) == true);
    assert(is_decreasing([1,2,3,4],strict=true) == false);
    assert(is_decreasing([4,2,3,1],strict=true) == false);
    assert(is_decreasing([4,2,2,1],strict=true) == false);
    assert(is_decreasing([4,3,2,1],strict=true) == true);
    assert(is_decreasing(reverse(["AB","BC","DF"])) == true);
    assert(is_decreasing(reverse(["AB","DC","CF"])) == false);    
    assert(is_decreasing(reverse([[1,2],[1,4],[2,3],[2,2]]))==false);
    assert(is_decreasing(reverse([[1,2],[1,4],[2,3],[2,3]]))==true);
    assert(is_decreasing(reverse([[1,2],[1,4],[2,3],[2,3]]),strict=true)==false);
    assert(is_decreasing("ABCFZ")==false);
    assert(is_decreasing("ZYWRA")==true);    
}
test_is_decreasing();



module test_are_ends_equal() {
    assert(!are_ends_equal([[1,2,3],[4,5,6],[1,8,9]]));
    assert(are_ends_equal([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]));
    assert(are_ends_equal([1,2,3,1.00004],eps=1e-2));
    assert(are_ends_equal([3]));
}
test_are_ends_equal();




module test_find_approx() {
    assert(find_approx(1, [2,3,1.05,4,1,2,.99], eps=.1)==2);
    assert(find_approx(1, [2,3,1.05,4,1,2,.99], all=true, eps=.1)==[2,4,6]);
    assert(find_approx(1, [2,3,4])==undef);
    assert(find_approx(1, [2,3,4],all=true)==[]);
    assert(find_approx(1, [])==undef);
    assert(find_approx(1, [], all=true)==[]);
}
test_find_approx();
    


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

module test_all_zero() {
    assert(all_zero(0));
    assert(all_zero([0,0,0]));
    assert(!all_zero([[0,0,0],[0,0]]));
    assert(all_zero([EPSILON/2,EPSILON/2,EPSILON/2]));
    assert(!all_zero(1e-3));
    assert(!all_zero([0,0,1e-3]));
    assert(!all_zero([EPSILON*10,0,0]));
    assert(!all_zero([0,EPSILON*10,0]));
    assert(!all_zero([0,0,EPSILON*10]));
    assert(!all_zero(true));
    assert(!all_zero(false));
    assert(!all_zero(INF));
    assert(!all_zero(-INF));
    assert(!all_zero(NAN));
    assert(!all_zero("foo"));
    assert(!all_zero([]));
    assert(!all_zero([0:1:2]));
}
test_all_zero();


module test_all_equal() {
    assert(all_equal([1,1,1,1]));
    assert(all_equal([[3,4],[3,4],[3,4]]));
    assert(!all_equal([1,2,1,1]));
    assert(!all_equal([1,1.001,1,1.001,.999]));
    assert(all_equal([1,1.001,1,1.001,.999],eps=.01));
}
test_all_equal();


module test_all_nonzero() {
    assert(!all_nonzero(0));
    assert(!all_nonzero([0,0,0]));
    assert(!all_nonzero([[0,0,0],[0,0]]));
    assert(!all_nonzero([EPSILON/2,EPSILON/2,EPSILON/2]));
    assert(all_nonzero(1e-3));
    assert(!all_nonzero([0,0,1e-3]));
    assert(!all_nonzero([EPSILON*10,0,0]));
    assert(!all_nonzero([0,EPSILON*10,0]));
    assert(!all_nonzero([0,0,EPSILON*10]));
    assert(all_nonzero([1e-3,1e-3,1e-3]));
    assert(all_nonzero([EPSILON*10,EPSILON*10,EPSILON*10]));
    assert(!all_nonzero(true));
    assert(!all_nonzero(false));
    assert(!all_nonzero(INF));
    assert(!all_nonzero(-INF));
    assert(!all_nonzero(NAN));
    assert(!all_nonzero("foo"));
    assert(!all_nonzero([]));
    assert(!all_nonzero([0:1:2]));
}
test_all_nonzero();


module test_all_positive() {
    assert(!all_positive(-2));
    assert(!all_positive(0));
    assert(all_positive(2));
    assert(!all_positive([0,0,0]));
    assert(!all_positive([0,1,2]));
    assert(all_positive([3,1,2]));
    assert(!all_positive([3,-1,2]));
    assert(!all_positive([]));
    assert(!all_positive(true));
    assert(!all_positive(false));
    assert(!all_positive("foo"));
    assert(!all_positive([0:1:2]));
}
test_all_positive();


module test_all_negative() {
    assert(all_negative(-2));
    assert(!all_negative(0));
    assert(!all_negative(2));
    assert(!all_negative([0,0,0]));
    assert(!all_negative([0,1,2]));
    assert(!all_negative([3,1,2]));
    assert(!all_negative([3,-1,2]));
    assert(all_negative([-3,-1,-2]));
    assert(!all_negative([-3,1,-2]));
    assert(!all_negative([[-5,-7],[-3,-1,-2]]));
    assert(!all_negative([[-5,-7],[-3,1,-2]]));
    assert(!all_negative([]));
    assert(!all_negative(true));
    assert(!all_negative(false));
    assert(!all_negative("foo"));
    assert(!all_negative([0:1:2]));
}
test_all_negative();


module test_all_nonpositive() {
    assert(all_nonpositive(-2));
    assert(all_nonpositive(0));
    assert(!all_nonpositive(2));
    assert(all_nonpositive([0,0,0]));
    assert(!all_nonpositive([0,1,2]));
    assert(all_nonpositive([0,-1,-2]));
    assert(!all_nonpositive([3,1,2]));
    assert(!all_nonpositive([3,-1,2]));
    assert(!all_nonpositive([]));
    assert(!all_nonpositive(true));
    assert(!all_nonpositive(false));
    assert(!all_nonpositive("foo"));
    assert(!all_nonpositive([0:1:2]));
}
test_all_nonpositive();


module test_all_nonnegative() {
    assert(!all_nonnegative(-2));
    assert(all_nonnegative(0));
    assert(all_nonnegative(2));
    assert(all_nonnegative([0,0,0]));
    assert(all_nonnegative([0,1,2]));
    assert(all_nonnegative([3,1,2]));
    assert(!all_nonnegative([3,-1,2]));
    assert(!all_nonnegative([-3,-1,-2]));
    assert(!all_nonnegative([[-5,-7],[-3,-1,-2]]));
    assert(!all_nonnegative([[-5,-7],[-3,1,-2]]));
    assert(!all_nonnegative([[5,7],[3,-1,2]]));
    assert(!all_nonnegative([[5,7],[3,1,2]]));
    assert(!all_nonnegative([]));
    assert(!all_nonnegative(true));
    assert(!all_nonnegative(false));
    assert(!all_nonnegative("foo"));
    assert(!all_nonnegative([0:1:2]));
}
test_all_nonnegative();


module test_approx() {
    assert_equal(approx(PI, 3.141592653589793236), true);
    assert_equal(approx(PI, 3.1415926), false);
    assert_equal(approx(PI, 3.1415926, eps=1e-6), true);
    assert_equal(approx(-PI, -3.141592653589793236), true);
    assert_equal(approx(-PI, -3.1415926), false);
    assert_equal(approx(-PI, -3.1415926, eps=1e-6), true);
    assert_equal(approx(1/3, 0.3333333333), true);
    assert_equal(approx(-1/3, -0.3333333333), true);
    assert_equal(approx(10*[cos(30),sin(30)], 10*[sqrt(3)/2, 1/2]), true);
    assert_equal(approx([1,[1,undef]], [1+1e-12,[1,true]]), false);
    assert_equal(approx([1,[1,undef]], [1+1e-12,[1,undef]]), true);
}
test_approx();



module test_group_data() {
    assert_equal(group_data([1,2,0], ["A","B","C"]), [["C"],["A"],["B"]]);
    assert_equal(group_data([1,3,0], ["A","B","C"]), [["C"],["A"],[],["B"]]);
    assert_equal(group_data([5,3,1], ["A","B","C"]), [[],["C"],[],["B"],[],["A"]]);
    assert_equal(group_data([1,3,1], ["A","B","C"]), [[],["A","C"],[],["B"]]);
}
test_group_data();


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


