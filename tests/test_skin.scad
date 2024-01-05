include <../std.scad>
include <../skin.scad>


module test_skin() {
    profiles = [
        [[-100,-100,0], [0,100,0], [100,-100,0]],
        [[-100,-100,100], [-100,100,100], [100,100,100], [100,-100,100]],
    ];
    vnf1 = skin(profiles, slices=0, caps=false, method="distance");
    assert_equal(vnf1, [[[-100,-100,0],[0,100,0],[0,100,0],[100,-100,0],[-100,-100,100],[-100,100,100],[100,100,100],[100,-100,100]],[[0,5,4],[0,1,5],[5,2,6],[2,3,6],[6,3,7],[3,0,7],[7,0,4]]]);
                       
    vnf2 = skin(profiles, slices=0, caps=true, method="distance");
    assert_equal(vnf2,[[[-100,-100,0],[0,100,0],[0,100,0],[100,-100,0],[-100,-100,100],[-100,100,100],[100,100,100],[100,-100,100]],[[3,2,1,0],[4,5,6,7],[0,5,4],[0,1,5],[5,2,6],[2,3,6],[6,3,7],[3,0,7],[7,0,4]]]);
}
test_skin();


module test_sweep() {
    multi_region = [
        [[10, 0], [ 0, 0], [ 0, 10], [10, 10]],
        [[30, 0], [20, 0], [20, 10], [30, 10]]
    ];
    transforms = [ up(10), down(10) ];

    vnf1 = sweep(multi_region,transforms,closed=false,caps=false);
    assert(len(vnf1[0])==8*2 && len(vnf1[1])==8*2);

    vnf2 = sweep(multi_region,transforms,closed=false,caps=false,style="quincunx");
    assert(len(vnf2[0])==8*3 && len(vnf2[1])==8*4);
}
test_sweep();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
