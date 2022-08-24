include <../std.scad>


// 2D

module test_affine2d_identity() {
    assert(affine2d_identity() == [[1,0,0],[0,1,0],[0,0,1]]);
}
test_affine2d_identity();


module test_affine2d_translate() {
    assert(affine2d_translate([0,0]) == [[1,0,0],[0,1,0],[0,0,1]]);
    assert(affine2d_translate([10,20]) == [[1,0,10],[0,1,20],[0,0,1]]);
    assert(affine2d_translate([20,10]) == [[1,0,20],[0,1,10],[0,0,1]]);
}
test_affine2d_translate();


module test_affine2d_scale() {
    assert(affine2d_scale([1,1]) == [[1,0,0],[0,1,0],[0,0,1]]);
    assert(affine2d_scale([2,3]) == [[2,0,0],[0,3,0],[0,0,1]]);
    assert(affine2d_scale([5,4]) == [[5,0,0],[0,4,0],[0,0,1]]);
}
test_affine2d_scale();


module test_affine2d_mirror() {
    assert(approx(affine2d_mirror([1,1]),[[0,-1,0],[-1,0,0],[0,0,1]]));
    assert(affine2d_mirror([1,0]) == [[-1,0,0],[0,1,0],[0,0,1]]);
    assert(affine2d_mirror([0,1]) == [[1,0,0],[0,-1,0],[0,0,1]]);
}
test_affine2d_mirror();


module test_affine2d_zrot() {
    for(a = [-360:2/3:360]) {
        assert(affine2d_zrot(a) == [[cos(a),-sin(a),0],[sin(a),cos(a),0],[0,0,1]]);
    }
}
test_affine2d_zrot();


module test_affine2d_skew() {
    for(ya = [-89:3:89]) {
        for(xa = [-89:3:89]) {
            assert(affine2d_skew(xa=xa, ya=ya) == [[1,tan(xa),0],[tan(ya),1,0],[0,0,1]]);
        }
    }
}
test_affine2d_skew();


// 3D

module test_affine3d_identity() {
    assert(affine3d_identity() == [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
}
test_affine3d_identity();


module test_affine3d_translate() {
    assert(affine3d_translate([10,20,30]) == [[1,0,0,10],[0,1,0,20],[0,0,1,30],[0,0,0,1]]);
    assert(affine3d_translate([3,2,1]) == [[1,0,0,3],[0,1,0,2],[0,0,1,1],[0,0,0,1]]);
}
test_affine3d_translate();


module test_affine3d_scale() {
    assert(affine3d_scale([3,2,4]) == [[3,0,0,0],[0,2,0,0],[0,0,4,0],[0,0,0,1]]);
}
test_affine3d_scale();


module test_affine3d_mirror() {
    assert(affine3d_mirror([1,0,0]) == [[-1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert(affine3d_mirror([0,1,0]) == [[1,0,0,0],[0,-1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert(affine3d_mirror([0,0,1]) == [[1,0,0,0],[0,1,0,0],[0,0,-1,0],[0,0,0,1]]);
    assert(approx(affine3d_mirror([1,1,1]), [[1/3,-2/3,-2/3,0],[-2/3,1/3,-2/3,0],[-2/3,-2/3,1/3,0],[0,0,0,1]]));
}
test_affine3d_mirror();


module test_affine3d_xrot() {
    for(a = [-360:2/3:360]) {
        assert(approx(affine3d_xrot(a), [[1,0,0,0],[0,cos(a),-sin(a),0],[0,sin(a),cos(a),0],[0,0,0,1]]));
    }
}
test_affine3d_xrot();


module test_affine3d_yrot() {
    for(a = [-360:2/3:360]) {
        assert(approx(affine3d_yrot(a), [[cos(a),0,sin(a),0],[0,1,0,0],[-sin(a),0,cos(a),0],[0,0,0,1]]));
    }
}
test_affine3d_yrot();


module test_affine3d_zrot() {
    for(a = [-360:2/3:360]) {
        assert(approx(affine3d_zrot(a), [[cos(a),-sin(a),0,0],[sin(a),cos(a),0,0],[0,0,1,0],[0,0,0,1]]));
    }
}
test_affine3d_zrot();


module test_affine3d_rot_by_axis() {
    for(a = [-360:2/3:360]) {
        assert(approx(affine3d_rot_by_axis(RIGHT,a), [[1,0,0,0],[0,cos(a),-sin(a),0],[0,sin(a),cos(a),0],[0,0,0,1]]));
        assert(approx(affine3d_rot_by_axis(BACK,a), [[cos(a),0,sin(a),0],[0,1,0,0],[-sin(a),0,cos(a),0],[0,0,0,1]]));
        assert(approx(affine3d_rot_by_axis(UP,a), [[cos(a),-sin(a),0,0],[sin(a),cos(a),0,0],[0,0,1,0],[0,0,0,1]]));
    }
}
test_affine3d_rot_by_axis();


module test_affine3d_rot_from_to() {
    assert(approx(affine3d_rot_from_to(UP,FRONT), affine3d_xrot(90)));
    assert(approx(affine3d_rot_from_to(UP,RIGHT), affine3d_yrot(90)));
    assert(approx(affine3d_rot_from_to(BACK,LEFT), affine3d_zrot(90)));
}
test_affine3d_rot_from_to();


module test_affine3d_skew() {
    assert(affine3d_skew(sxy=2) == [[1,2,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert(affine3d_skew(sxz=2) == [[1,0,2,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert(affine3d_skew(syx=2) == [[1,0,0,0],[2,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert(affine3d_skew(syz=2) == [[1,0,0,0],[0,1,2,0],[0,0,1,0],[0,0,0,1]]);
    assert(affine3d_skew(szx=2) == [[1,0,0,0],[0,1,0,0],[2,0,1,0],[0,0,0,1]]);
    assert(affine3d_skew(szy=2) == [[1,0,0,0],[0,1,0,0],[0,2,1,0],[0,0,0,1]]);
}
test_affine3d_skew();


module test_affine3d_skew_xy() {
    for(ya = [-89:3:89]) {
        for(xa = [-89:3:89]) {
            assert(affine3d_skew_xy(xa=xa, ya=ya) == [[1,tan(xa),0,0],[tan(ya),1,0,0],[0,0,1,0],[0,0,0,1]]);
        }
    }
}
test_affine3d_skew_xy();


module test_affine3d_skew_xz() {
    for(za = [-89:3:89]) {
        for(xa = [-89:3:89]) {
            assert(affine3d_skew_xz(xa=xa, za=za) == [[1,0,tan(xa),0],[0,1,0,0],[tan(za),0,1,0],[0,0,0,1]]);
        }
    }
}
test_affine3d_skew_xz();


module test_affine3d_skew_yz() {
    for(za = [-89:3:89]) {
        for(ya = [-89:3:89]) {
            assert(affine3d_skew_yz(ya=ya, za=za) == [[1,0,0,0],[0,1,tan(ya),0],[0,tan(za),1,0],[0,0,0,1]]);
        }
    }
}
test_affine3d_skew_yz();


////////////////////////////


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
