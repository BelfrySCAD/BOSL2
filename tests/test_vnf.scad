include <../std.scad>
include <../vnf.scad>


module test_is_vnf() {
    assert(is_vnf([[],[]]));
    assert(!is_vnf([]));
    assert(is_vnf([[[-1,-1,-1],[1,-1,-1],[0,1,-1],[0,0,1]],[[0,1,2],[0,3,1],[1,3,2],[2,3,0]]]));
}
test_is_vnf();


module test_is_vnf_list() {
    assert(is_vnf_list([]));
    assert(!is_vnf_list([[],[]]));
    assert(is_vnf_list([[[],[]]]));
    assert(!is_vnf_list([[[-1,-1,-1],[1,-1,-1],[0,1,-1],[0,0,1]],[[0,1,2],[0,3,1],[1,3,2],[2,3,0]]]));
    assert(is_vnf_list([[[[-1,-1,-1],[1,-1,-1],[0,1,-1],[0,0,1]],[[0,1,2],[0,3,1],[1,3,2],[2,3,0]]]]));
}
test_is_vnf_list();


module test_vnf_vertices() {
    vnf = [[[-1,-1,-1],[1,-1,-1],[0,1,-1],[0,0,1]],[[0,1,2],[0,3,1],[1,3,2],[2,3,0]]];
    assert(vnf_vertices(vnf) == vnf[0]);
}
test_vnf_vertices();


module test_vnf_faces() {
    vnf = [[[-1,-1,-1],[1,-1,-1],[0,1,-1],[0,0,1]],[[0,1,2],[0,3,1],[1,3,2],[2,3,0]]];
    assert(vnf_faces(vnf) == vnf[1]);
}
test_vnf_faces();


module test_vnf_from_polygons() {
    verts = [[-1,-1,-1],[1,-1,-1],[0,1,-1],[0,0,1]];
    faces = [[0,1,2],[0,3,1],[2,3,0],[0,1,0]];      // Last face has zero area
    assert(vnf_merge_points(
                     vnf_from_polygons([for (face=faces) select(verts,face)])) == [verts,select(faces,0,-2)]); 
}
test_vnf_from_polygons();



module test_vnf_volume() {
    assert_approx(vnf_volume(cube(100, center=false)), 1000000);
    assert(approx(vnf_volume(sphere(d=100, anchor=BOT, $fn=144)) / (4/3*PI*pow(50,3)),1, eps=.001));
}
test_vnf_volume();



module test_vnf_area(){
    assert(approx(vnf_area(sphere(d=100, $fn=144)) / (4*PI*50*50),1, eps=1e-3));
}
test_vnf_area();


module test_vnf_join() {
    vnf1 = vnf_from_polygons([[[-1,-1,-1],[1,-1,-1],[0,1,-1]]]);
    vnf2 = vnf_from_polygons([[[1,1,1],[-1,1,1],[0,1,-1]]]);
    assert(vnf_join([vnf1,vnf2]) == [[[-1,-1,-1],[1,-1,-1],[0,1,-1],[1,1,1],[-1,1,1],[0,1,-1]],[[0,1,2],[3,4,5]]]);
}
test_vnf_join();


module test_vnf_triangulate() {
    vnf = [[[-1,-1,0],[1,-1,0],[1,1,0],[-1,1,0]],[[0,1,2,3]]];
    assert(vnf_triangulate(vnf) == [[[-1,-1,0],[1,-1,0],[1,1,0],[-1,1,0]], [[0,1,2],[2,3,0]]]);
}
test_vnf_triangulate();


module test_vnf_vertex_array() {
    vnf1 = vnf_vertex_array(
        points=[for (h=[0:100:100]) [[100,-50,h],[-100,-50,h],[0,100,h]]],
        col_wrap=true, caps=true
    );
    vnf2 = vnf_vertex_array(
        points=[for (h=[0:100:100]) [[100,-50,h],[-100,-50,h],[0,100,h]]],
        col_wrap=true, caps=true, style="alt"
    );
    vnf3 = vnf_vertex_array(
        points=[for (h=[0:100:100]) [[100,-50,h],[-100,-50,h],[0,100,h]]],
        col_wrap=true, caps=true, style="quincunx"
    );
    assert(vnf1 == [[[100,-50,0],[-100,-50,0],[0,100,0],[100,-50,100],[-100,-50,100],[0,100,100]],[[2,1,0],[3,4,5],[0,4,3],[0,1,4],[1,5,4],[1,2,5],[2,3,5],[2,0,3]]]);
    assert(vnf2 == [[[100,-50,0],[-100,-50,0],[0,100,0],[100,-50,100],[-100,-50,100],[0,100,100]],[[2,1,0],[3,4,5],[0,1,3],[3,1,4],[1,2,4],[4,2,5],[2,0,5],[5,0,3]]]);
    assert(vnf3 == [[[100,-50,0],[-100,-50,0],[0,100,0],[100,-50,100],[-100,-50,100],[0,100,100],[0,-50,50],[-50,25,50],[50,25,50]],[[2,1,0],[3,4,5],[0,6,3],[3,6,4],[4,6,1],[1,6,0],[1,7,4],[4,7,5],[5,7,2],[2,7,1],[2,8,5],[5,8,3],[3,8,0],[0,8,2]]]);
}
test_vnf_vertex_array();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
