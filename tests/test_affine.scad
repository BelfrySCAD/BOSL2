include <../std.scad>


module test_ident() {
    assert(ident(3) == [[1,0,0],[0,1,0],[0,0,1]]);
    assert(ident(4) == [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
}
test_ident();


module test_is_2d_transform() {
    assert(!is_2d_transform(affine2d_identity()));
    assert(!is_2d_transform(affine2d_translate([5,8])));
    assert(!is_2d_transform(affine2d_scale([3,4])));
    assert(!is_2d_transform(affine2d_zrot(30)));
    assert(!is_2d_transform(affine2d_mirror([-1,1])));
    assert(!is_2d_transform(affine2d_skew(30,15)));

    assert(is_2d_transform(affine3d_identity()));
    assert(is_2d_transform(affine3d_translate([30,40,0])));
    assert(!is_2d_transform(affine3d_translate([30,40,50])));
    assert(is_2d_transform(affine3d_scale([3,4,1])));
    assert(!is_2d_transform(affine3d_xrot(30)));
    assert(!is_2d_transform(affine3d_yrot(30)));
    assert(is_2d_transform(affine3d_zrot(30)));
    assert(is_2d_transform(affine3d_skew(sxy=2)));
    assert(is_2d_transform(affine3d_skew(syx=2)));
    assert(!is_2d_transform(affine3d_skew(szx=2)));
    assert(!is_2d_transform(affine3d_skew(szy=2)));
}
test_is_2d_transform();


module test_is_affine() {
    assert(is_affine(affine2d_scale([2,3])));
    assert(is_affine(affine3d_scale([2,3,4])));
    assert(!is_affine(affine3d_scale([2,3,4]),2));
    assert(is_affine(affine2d_scale([2,3]),2));
    assert(is_affine(affine3d_scale([2,3,4]),3));
    assert(!is_affine(affine2d_scale([2,3]),3));
}
test_is_affine();


module test_affine2d_to_3d() {
    assert(affine2d_to_3d(affine2d_identity()) == affine3d_identity());
    assert(affine2d_to_3d(affine2d_translate([30,40])) == affine3d_translate([30,40,0]));
    assert(affine2d_to_3d(affine2d_scale([3,4])) == affine3d_scale([3,4,1]));
    assert(affine2d_to_3d(affine2d_zrot(30)) == affine3d_zrot(30));
}
test_affine2d_to_3d();


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
            assert(affine3d_skew_xy(xa=xa, ya=ya) == [[1,0,tan(xa),0],[0,1,tan(ya),0],[0,0,1,0],[0,0,0,1]]);
        }
    }
}
test_affine3d_skew_xy();


module test_affine3d_skew_xz() {
    for(za = [-89:3:89]) {
        for(xa = [-89:3:89]) {
            assert(affine3d_skew_xz(xa=xa, za=za) == [[1,tan(xa),0,0],[0,1,0,0],[0,tan(za),1,0],[0,0,0,1]]);
        }
    }
}
test_affine3d_skew_xz();


module test_affine3d_skew_yz() {
    for(za = [-89:3:89]) {
        for(ya = [-89:3:89]) {
            assert(affine3d_skew_yz(ya=ya, za=za) == [[1,0,0,0],[tan(ya),1,0,0],[tan(za),0,1,0],[0,0,0,1]]);
        }
    }
}
test_affine3d_skew_yz();


////////////////////////////

module test_affine3d_frame_map() {
    assert(approx(affine3d_frame_map(x=[1,1,0], y=[-1,1,0]), affine3d_zrot(45)));
}
test_affine3d_frame_map();


module test_apply() {
    assert(approx(apply(affine3d_xrot(90),2*UP),2*FRONT));
    assert(approx(apply(affine3d_yrot(90),2*UP),2*RIGHT));
    assert(approx(apply(affine3d_zrot(90),2*UP),2*UP));
    assert(approx(apply(affine3d_zrot(90),2*RIGHT),2*BACK));
    assert(approx(apply(affine3d_zrot(90),2*BACK+2*RIGHT),2*BACK+2*LEFT));
    assert(approx(apply(affine3d_xrot(135),2*BACK+2*UP),2*sqrt(2)*FWD));
    assert(approx(apply(affine3d_yrot(135),2*RIGHT+2*UP),2*sqrt(2)*DOWN));
    assert(approx(apply(affine3d_zrot(45),2*BACK+2*RIGHT),2*sqrt(2)*BACK));

    module check_path_apply(mat,path)
        assert_approx(apply(mat,path),path3d([for (p=path) mat*concat(p,1)]));

    check_path_apply(xrot(45), path3d(rect(100,center=true)));
    check_path_apply(yrot(45), path3d(rect(100,center=true)));
    check_path_apply(zrot(45), path3d(rect(100,center=true)));
    check_path_apply(rot([20,30,40])*scale([0.9,1.1,1])*move([10,20,30]), path3d(rect(100,center=true)));

    module check_patch_apply(mat,patch)
        assert_approx(apply(mat,patch), [for (path=patch) path3d([for (p=path) mat*concat(p,1)])]);

    flat = [for (x=[-50:25:50]) [for (y=[-50:25:50]) [x,y,0]]];
    check_patch_apply(xrot(45), flat);
    check_patch_apply(yrot(45), flat);
    check_patch_apply(zrot(45), flat);
    check_patch_apply(rot([20,30,40])*scale([0.9,1.1,1])*move([10,20,30]), flat);
}
test_apply();


module test_rot_decode() {
   Tlist = [
             rot(37),
             xrot(49),
             yrot(88),
             rot(37,v=[1,3,3]),
             rot(41,v=[2,-3,4]),
             rot(180),
             xrot(180),
             yrot(180),
             rot(180, v=[3,2,-5], cp=[3,5,18]),
             rot(0.1, v=[1,2,3]),
             rot(-47,v=[3,4,5],cp=[9,3,4]),
             rot(197,v=[13,4,5],cp=[9,-3,4]),
             move([3,4,5]),
             move([3,4,5]) * rot(a=56, v=[5,3,-3], cp=[2,3,4]),
             ident(4)
           ];
    errlist = [for(T = Tlist)
                  let(
                       parm = rot_decode(T),
                       restore = move(parm[3])*rot(a=parm[0],v=parm[1],cp=parm[2])
                  )
                  norm_fro(restore-T)];
    assert(max(errlist)<1e-13);
}
test_rot_decode();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
