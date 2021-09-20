include<../std.scad>

module test_is_path() {
    assert(is_path([[1,2,3],[4,5,6]]));
    assert(is_path([[1,2,3],[4,5,6],[7,8,9]]));
    assert(!is_path(123));
    assert(!is_path("foo"));
    assert(!is_path(true));
    assert(!is_path([]));
    assert(!is_path([[]]));
    assert(!is_path([["foo","bar","baz"]]));
    assert(!is_path([[1,2,3]]));
    assert(!is_path([["foo","bar","baz"],["qux","quux","quuux"]]));
}
test_is_path();


module test_is_closed_path() {
    assert(!is_closed_path([[1,2,3],[4,5,6],[1,8,9]]));
    assert(is_closed_path([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]));
}
test_is_closed_path();


module test_close_path() {
    assert(close_path([[1,2,3],[4,5,6],[1,8,9]]) == [[1,2,3],[4,5,6],[1,8,9],[1,2,3]]);
    assert(close_path([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]) == [[1,2,3],[4,5,6],[1,8,9],[1,2,3]]);
}
test_close_path();


module test_cleanup_path() {
    assert(cleanup_path([[1,2,3],[4,5,6],[1,8,9]]) == [[1,2,3],[4,5,6],[1,8,9]]);
    assert(cleanup_path([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]) == [[1,2,3],[4,5,6],[1,8,9]]);
}
test_cleanup_path();


module test_path_merge_collinear() {
    path = [[-20,-20], [-10,-20], [0,-10], [10,0], [20,10], [20,20], [15,30]];
    assert(path_merge_collinear(path) == [[-20,-20], [-10,-20], [20,10], [20,20], [15,30]]);
}
test_path_merge_collinear();


