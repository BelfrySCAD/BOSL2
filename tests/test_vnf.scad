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


module test_vnf_get_vertex() {
    vnf = [[[-1,-1,-1],[1,-1,-1],[0,1,-1],[0,0,1]],[[0,1,2],[0,3,1],[1,3,2],[2,3,0]]];
    assert(vnf_get_vertex(vnf,[0,1,-1]) == [2,vnf]);
    assert(vnf_get_vertex(vnf,[0,1,2]) == [4,[concat(vnf[0],[[0,1,2]]),vnf[1]]]);
    assert(vnf_get_vertex(vnf,[[0,1,-1],[0,1,2]]) == [[2,4],[concat(vnf[0],[[0,1,2]]),vnf[1]]]);
}
test_vnf_get_vertex();


module test_vnf_add_face() {
    verts = [[-1,-1,-1],[1,-1,-1],[0,1,-1],[0,0,1]];
    faces = [[0,1,2],[0,3,1],[1,3,2],[2,3,0]];
    vnf1 = vnf_add_face(pts=select(verts,faces[0]));
    vnf2 = vnf_add_face(vnf1, pts=select(verts,faces[1]));
    vnf3 = vnf_add_face(vnf2, pts=select(verts,faces[2]));
    vnf4 = vnf_add_face(vnf3, pts=select(verts,faces[3]));
    assert(vnf1 == [select(verts,0,2),select(faces,[0])]);
    assert(vnf2 == [verts,select(faces,[0:1])]);
    assert(vnf3 == [verts,select(faces,[0:2])]);
    assert(vnf4 == [verts,faces]);
}
test_vnf_add_face();


module test_vnf_add_faces() {
    verts = [[-1,-1,-1],[1,-1,-1],[0,1,-1],[0,0,1]];
    faces = [[0,1,2],[0,3,1],[1,3,2],[2,3,0]];
    assert(vnf_add_faces(faces=[for (face=faces) select(verts,face)]) == [verts,faces]);
}
test_vnf_add_faces();


module test_vnf_centroid() {
    assert_approx(vnf_centroid(cube(100, center=false)), [50,50,50]);
    assert_approx(vnf_centroid(cube(100, center=true)), [0,0,0]);
    assert_approx(vnf_centroid(cube(100, anchor=ALLPOS)), [-50,-50,-50]);
    assert_approx(vnf_centroid(cube(100, anchor=BOT)), [0,0,50]);
    assert_approx(vnf_centroid(cube(100, anchor=TOP)), [0,0,-50]);
    assert_approx(vnf_centroid(sphere(d=100, anchor=CENTER, $fn=36)), [0,0,0]);
    assert_approx(vnf_centroid(sphere(d=100, anchor=BOT, $fn=36)), [0,0,50]);
    ellipse = xscale(2, p=circle($fn=24, r=3));
    assert_approx(vnf_centroid(path_sweep(pentagon(r=1), path3d(ellipse), closed=true)),[0,0,0]);}
test_vnf_centroid();


module test_vnf_volume() {
    assert_approx(vnf_volume(cube(100, center=false)), 1000000);
    assert(approx(vnf_volume(sphere(d=100, anchor=BOT, $fn=144)), 4/3*PI*pow(50,3), eps=1e3));
}
test_vnf_volume();


module test_vnf_merge() {
    vnf1 = vnf_add_face(pts=[[-1,-1,-1],[1,-1,-1],[0,1,-1]]);
    vnf2 = vnf_add_face(pts=[[1,1,1],[-1,1,1],[0,1,-1]]);
    assert(vnf_merge([vnf1,vnf2]) == [[[-1,-1,-1],[1,-1,-1],[0,1,-1],[1,1,1],[-1,1,1],[0,1,-1]],[[0,1,2],[3,4,5]]]);
}
test_vnf_merge();


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
    assert(vnf1 == [[[100,-50,0],[-100,-50,0],[0,100,0],[100,-50,100],[-100,-50,100],[0,100,100]],[[0,4,3],[0,1,4],[1,5,4],[1,2,5],[2,3,5],[2,0,3],[2,1,0],[3,4,5]]]);
    assert(vnf2 == [[[100,-50,0],[-100,-50,0],[0,100,0],[100,-50,100],[-100,-50,100],[0,100,100]],[[0,1,3],[3,1,4],[1,2,4],[4,2,5],[2,0,5],[5,0,3],[2,1,0],[3,4,5]]]);
    assert(vnf3 == [[[100,-50,0],[-100,-50,0],[0,100,0],[100,-50,100],[-100,-50,100],[0,100,100],[0,-50,50],[-50,25,50],[50,25,50]],[[0,6,3],[3,6,4],[4,6,1],[1,6,0],[1,7,4],[4,7,5],[5,7,2],[2,7,1],[2,8,5],[5,8,3],[3,8,0],[0,8,2],[2,1,0],[3,4,5]]]);
}
test_vnf_vertex_array();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
