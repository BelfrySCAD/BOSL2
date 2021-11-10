include <../std.scad>


module test__is_edge_array() {
    assert(_is_edge_array([[0,0,0,0],[0,0,0,0],[0,0,0,0]]));
    assert(_is_edge_array([[1,1,1,1],[1,1,1,1],[1,1,1,1]]));
    assert(!_is_edge_array([[1,1,1],[1,1,1],[1,1,1]]));
    assert(!_is_edge_array([[1,1,1,1,1],[1,1,1,1,1],[1,1,1,1,1]]));
    assert(!_is_edge_array([[1,1,1,1],[1,1,1,1]]));
    assert(!_is_edge_array([1,1,1,1]));
    assert(!_is_edge_array("foo"));
    assert(!_is_edge_array(42));
    assert(!_is_edge_array(true));
    assert(_is_edge_array(_edges(["X","Y"])));
}
test__is_edge_array();


module test__edge_set() {
    // Edge set pass through
    assert(_edge_set([[1,1,1,1],[0,1,0,1],[0,0,0,0]]) == [[1,1,1,1],[0,1,0,1],[0,0,0,0]]);

    // Vectors towards corners
    assert(_edge_set([-1,-1,-1]) == [[1,0,0,0],[1,0,0,0],[1,0,0,0]]);
    assert(_edge_set([-1,-1, 1]) == [[0,0,1,0],[0,0,1,0],[1,0,0,0]]);
    assert(_edge_set([-1, 1,-1]) == [[0,1,0,0],[1,0,0,0],[0,0,1,0]]);
    assert(_edge_set([-1, 1, 1]) == [[0,0,0,1],[0,0,1,0],[0,0,1,0]]);
    assert(_edge_set([ 1,-1,-1]) == [[1,0,0,0],[0,1,0,0],[0,1,0,0]]);
    assert(_edge_set([ 1,-1, 1]) == [[0,0,1,0],[0,0,0,1],[0,1,0,0]]);
    assert(_edge_set([ 1, 1,-1]) == [[0,1,0,0],[0,1,0,0],[0,0,0,1]]);
    assert(_edge_set([ 1, 1, 1]) == [[0,0,0,1],[0,0,0,1],[0,0,0,1]]);

    // Vectors towards edges
    assert(_edge_set([ 0,-1,-1]) == [[1,0,0,0],[0,0,0,0],[0,0,0,0]]);
    assert(_edge_set([ 0, 1,-1]) == [[0,1,0,0],[0,0,0,0],[0,0,0,0]]);
    assert(_edge_set([ 0,-1, 1]) == [[0,0,1,0],[0,0,0,0],[0,0,0,0]]);
    assert(_edge_set([ 0, 1, 1]) == [[0,0,0,1],[0,0,0,0],[0,0,0,0]]);
    assert(_edge_set([-1, 0,-1]) == [[0,0,0,0],[1,0,0,0],[0,0,0,0]]);
    assert(_edge_set([ 1, 0,-1]) == [[0,0,0,0],[0,1,0,0],[0,0,0,0]]);
    assert(_edge_set([-1, 0, 1]) == [[0,0,0,0],[0,0,1,0],[0,0,0,0]]);
    assert(_edge_set([ 1, 0, 1]) == [[0,0,0,0],[0,0,0,1],[0,0,0,0]]);
    assert(_edge_set([-1,-1, 0]) == [[0,0,0,0],[0,0,0,0],[1,0,0,0]]);
    assert(_edge_set([ 1,-1, 0]) == [[0,0,0,0],[0,0,0,0],[0,1,0,0]]);
    assert(_edge_set([-1, 1, 0]) == [[0,0,0,0],[0,0,0,0],[0,0,1,0]]);
    assert(_edge_set([ 1, 1, 0]) == [[0,0,0,0],[0,0,0,0],[0,0,0,1]]);

    // Vectors towards faces
    assert(_edge_set([ 0, 0,-1]) == [[1,1,0,0],[1,1,0,0],[0,0,0,0]]);
    assert(_edge_set([ 0, 0, 1]) == [[0,0,1,1],[0,0,1,1],[0,0,0,0]]);
    assert(_edge_set([ 0,-1, 0]) == [[1,0,1,0],[0,0,0,0],[1,1,0,0]]);
    assert(_edge_set([ 0, 1, 0]) == [[0,1,0,1],[0,0,0,0],[0,0,1,1]]);
    assert(_edge_set([-1, 0, 0]) == [[0,0,0,0],[1,0,1,0],[1,0,1,0]]);
    assert(_edge_set([ 1, 0, 0]) == [[0,0,0,0],[0,1,0,1],[0,1,0,1]]);

    // Named edge sets
    assert(_edge_set("X") == [[1,1,1,1],[0,0,0,0],[0,0,0,0]]);
    assert(_edge_set("Y") == [[0,0,0,0],[1,1,1,1],[0,0,0,0]]);
    assert(_edge_set("Z") == [[0,0,0,0],[0,0,0,0],[1,1,1,1]]);
    assert(_edge_set("NONE") == [[0,0,0,0],[0,0,0,0],[0,0,0,0]]);
    assert(_edge_set("ALL") == [[1,1,1,1],[1,1,1,1],[1,1,1,1]]);
}
test__edge_set();


module test__normalize_edges() {
    assert(_normalize_edges([[-2,-2,-2,-2],[-2,-2,-2,-2],[-2,-2,-2,-2]]) == [[0,0,0,0],[0,0,0,0],[0,0,0,0]]);
    assert(_normalize_edges([[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1]]) == [[0,0,0,0],[0,0,0,0],[0,0,0,0]]);
    assert(_normalize_edges([[0,0,0,0],[0,0,0,0],[0,0,0,0]]) == [[0,0,0,0],[0,0,0,0],[0,0,0,0]]);
    assert(_normalize_edges([[1,1,1,1],[1,1,1,1],[1,1,1,1]]) == [[1,1,1,1],[1,1,1,1],[1,1,1,1]]);
    assert(_normalize_edges([[2,2,2,2],[2,2,2,2],[2,2,2,2]]) == [[1,1,1,1],[1,1,1,1],[1,1,1,1]]);
}
test__normalize_edges();


module test__edges() {
    assert(_edges("X")==[[1,1,1,1],[0,0,0,0],[0,0,0,0]]);
    assert(_edges("Y")==[[0,0,0,0],[1,1,1,1],[0,0,0,0]]);
    assert(_edges("Z")==[[0,0,0,0],[0,0,0,0],[1,1,1,1]]);
    assert(_edges(["X"])==[[1,1,1,1],[0,0,0,0],[0,0,0,0]]);
    assert(_edges(["Y"])==[[0,0,0,0],[1,1,1,1],[0,0,0,0]]);
    assert(_edges(["Z"])==[[0,0,0,0],[0,0,0,0],[1,1,1,1]]);
    assert(_edges(["X","Y"])==[[1,1,1,1],[1,1,1,1],[0,0,0,0]]);
    assert(_edges(["X","Z"])==[[1,1,1,1],[0,0,0,0],[1,1,1,1]]);
    assert(_edges(["Y","Z"])==[[0,0,0,0],[1,1,1,1],[1,1,1,1]]);
    assert(_edges("ALL",except="X")==[[0,0,0,0],[1,1,1,1],[1,1,1,1]]);
    assert(_edges("ALL",except="Y")==[[1,1,1,1],[0,0,0,0],[1,1,1,1]]);
    assert(_edges("ALL",except="Z")==[[1,1,1,1],[1,1,1,1],[0,0,0,0]]);
    assert(_edges(["Y","Z"],except=[FRONT+RIGHT,FRONT+LEFT])==[[0,0,0,0],[1,1,1,1],[0,0,1,1]]);
}
test__edges();


module test__corner_edge_count() {
    edges = _edges([TOP,FRONT+RIGHT]);
    assert(_corner_edge_count(edges,TOP+FRONT+RIGHT) == 3);
    assert(_corner_edge_count(edges,TOP+FRONT+LEFT) == 2);
    assert(_corner_edge_count(edges,BOTTOM+FRONT+RIGHT) == 1);
    assert(_corner_edge_count(edges,BOTTOM+FRONT+LEFT) == 0);
}
test__corner_edge_count();


module test__corner_edges() {
    edges = _edges([TOP,FRONT+RIGHT]);
    assert_equal(_corner_edges(edges,TOP+FRONT+RIGHT), [1,1,1]);
    assert_equal(_corner_edges(edges,TOP+FRONT+LEFT), [1,1,0]);
    assert_equal(_corner_edges(edges,BOTTOM+FRONT+RIGHT), [0,0,1]);
    assert_equal(_corner_edges(edges,BOTTOM+FRONT+LEFT), [0,0,0]);
}
test__corner_edges();


module test__corners() {
    assert_equal(_corners(BOT + FRONT + LEFT ), [1,0,0,0,0,0,0,0]);
    assert_equal(_corners(BOT + FRONT + RIGHT), [0,1,0,0,0,0,0,0]);
    assert_equal(_corners(BOT + BACK  + LEFT ), [0,0,1,0,0,0,0,0]);
    assert_equal(_corners(BOT + BACK  + RIGHT), [0,0,0,1,0,0,0,0]);
    assert_equal(_corners(TOP + FRONT + LEFT ), [0,0,0,0,1,0,0,0]);
    assert_equal(_corners(TOP + FRONT + RIGHT), [0,0,0,0,0,1,0,0]);
    assert_equal(_corners(TOP + BACK  + LEFT ), [0,0,0,0,0,0,1,0]);
    assert_equal(_corners(TOP + BACK  + RIGHT), [0,0,0,0,0,0,0,1]);

    assert_equal(_corners(BOT   + FRONT),  [1,1,0,0,0,0,0,0]);
    assert_equal(_corners(BOT   + BACK ),  [0,0,1,1,0,0,0,0]);
    assert_equal(_corners(TOP   + FRONT),  [0,0,0,0,1,1,0,0]);
    assert_equal(_corners(TOP   + BACK ),  [0,0,0,0,0,0,1,1]);
    assert_equal(_corners(BOT   + LEFT ),  [1,0,1,0,0,0,0,0]);
    assert_equal(_corners(BOT   + RIGHT),  [0,1,0,1,0,0,0,0]);
    assert_equal(_corners(TOP   + LEFT ),  [0,0,0,0,1,0,1,0]);
    assert_equal(_corners(TOP   + RIGHT),  [0,0,0,0,0,1,0,1]);
    assert_equal(_corners(FRONT + LEFT ),  [1,0,0,0,1,0,0,0]);
    assert_equal(_corners(FRONT + RIGHT),  [0,1,0,0,0,1,0,0]);
    assert_equal(_corners(BACK  + LEFT ),  [0,0,1,0,0,0,1,0]);
    assert_equal(_corners(BACK  + RIGHT),  [0,0,0,1,0,0,0,1]);

    assert_equal(_corners(LEFT),   [1,0,1,0,1,0,1,0]);
    assert_equal(_corners(RIGHT),  [0,1,0,1,0,1,0,1]);
    assert_equal(_corners(FRONT),  [1,1,0,0,1,1,0,0]);
    assert_equal(_corners(BACK),   [0,0,1,1,0,0,1,1]);
    assert_equal(_corners(BOT),    [1,1,1,1,0,0,0,0]);
    assert_equal(_corners(TOP),    [0,0,0,0,1,1,1,1]);

    assert_equal(_corners([BOT + FRONT + LEFT ]), [1,0,0,0,0,0,0,0]);
    assert_equal(_corners([BOT + FRONT + RIGHT]), [0,1,0,0,0,0,0,0]);
    assert_equal(_corners([BOT + BACK  + LEFT ]), [0,0,1,0,0,0,0,0]);
    assert_equal(_corners([BOT + BACK  + RIGHT]), [0,0,0,1,0,0,0,0]);
    assert_equal(_corners([TOP + FRONT + LEFT ]), [0,0,0,0,1,0,0,0]);
    assert_equal(_corners([TOP + FRONT + RIGHT]), [0,0,0,0,0,1,0,0]);
    assert_equal(_corners([TOP + BACK  + LEFT ]), [0,0,0,0,0,0,1,0]);
    assert_equal(_corners([TOP + BACK  + RIGHT]), [0,0,0,0,0,0,0,1]);

    assert_equal(_corners([BOT   + FRONT]),  [1,1,0,0,0,0,0,0]);
    assert_equal(_corners([BOT   + BACK ]),  [0,0,1,1,0,0,0,0]);
    assert_equal(_corners([TOP   + FRONT]),  [0,0,0,0,1,1,0,0]);
    assert_equal(_corners([TOP   + BACK ]),  [0,0,0,0,0,0,1,1]);
    assert_equal(_corners([BOT   + LEFT ]),  [1,0,1,0,0,0,0,0]);
    assert_equal(_corners([BOT   + RIGHT]),  [0,1,0,1,0,0,0,0]);
    assert_equal(_corners([TOP   + LEFT ]),  [0,0,0,0,1,0,1,0]);
    assert_equal(_corners([TOP   + RIGHT]),  [0,0,0,0,0,1,0,1]);
    assert_equal(_corners([FRONT + LEFT ]),  [1,0,0,0,1,0,0,0]);
    assert_equal(_corners([FRONT + RIGHT]),  [0,1,0,0,0,1,0,0]);
    assert_equal(_corners([BACK  + LEFT ]),  [0,0,1,0,0,0,1,0]);
    assert_equal(_corners([BACK  + RIGHT]),  [0,0,0,1,0,0,0,1]);

    assert_equal(_corners([LEFT]),  [1,0,1,0,1,0,1,0]);
    assert_equal(_corners([RIGHT]), [0,1,0,1,0,1,0,1]);
    assert_equal(_corners([FRONT]), [1,1,0,0,1,1,0,0]);
    assert_equal(_corners([BACK]),  [0,0,1,1,0,0,1,1]);
    assert_equal(_corners([BOT]),   [1,1,1,1,0,0,0,0]);
    assert_equal(_corners([TOP]),   [0,0,0,0,1,1,1,1]);

    assert_equal(_corners([TOP,FRONT+RIGHT]), [0,1,0,0,1,1,1,1]);
}
test__corners();


module test__is_corner_array() {
    edges = _edges([TOP,FRONT+RIGHT]);
    corners = _corners([TOP,FRONT+RIGHT]);
    assert(!_is_corner_array(undef));
    assert(!_is_corner_array(true));
    assert(!_is_corner_array(false));
    assert(!_is_corner_array(INF));
    assert(!_is_corner_array(-INF));
    assert(!_is_corner_array(NAN));
    assert(!_is_corner_array(-4));
    assert(!_is_corner_array(0));
    assert(!_is_corner_array(4));
    assert(!_is_corner_array("foo"));
    assert(!_is_corner_array([]));
    assert(!_is_corner_array([4,5,6]));
    assert(!_is_corner_array([2:3:9]));
    assert(!_is_corner_array(edges));
    assert(_is_corner_array(corners));
}
test__is_corner_array();


module test__normalize_corners() {
    assert_equal(_normalize_corners([-2,-2,-2,-2,-2,-2,-2,-2]), [0,0,0,0,0,0,0,0]);
    assert_equal(_normalize_corners([-1,-1,-1,-1,-1,-1,-1,-1]), [0,0,0,0,0,0,0,0]);
    assert_equal(_normalize_corners([0,0,0,0,0,0,0,0]), [0,0,0,0,0,0,0,0]);
    assert_equal(_normalize_corners([1,1,1,1,1,1,1,1]), [1,1,1,1,1,1,1,1]);
    assert_equal(_normalize_corners([2,2,2,2,2,2,2,2]), [1,1,1,1,1,1,1,1]);
}
test__normalize_corners();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
