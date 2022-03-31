include <../std.scad>


module test_translate() {
    vals = [[-1,-2,-3],[0,0,0],[3,6,2],[1,2,3],[243,75,147]];
    for (val=vals) {
        assert_equal(translate(val), [[1,0,0,val.x],[0,1,0,val.y],[0,0,1,val.z],[0,0,0,1]]);
        assert_equal(translate(val, p=[1,2,3]), [1,2,3]+val);
    }
    // Verify that module at least doesn't crash.
    translate([-5,-5,-5]) translate([0,0,0]) translate([5,5,5]) union(){};
}
test_translate();


module test_move() {
    vals = [[-1,-2,-3],[0,0,0],[3,6,2],[1,2,3],[243,75,147]];
    for (val=vals) {
        assert_equal(move(val), [[1,0,0,val.x],[0,1,0,val.y],[0,0,1,val.z],[0,0,0,1]]);
        assert_equal(move(val, p=[1,2,3]), [1,2,3]+val);
    }
    // Verify that module at least doesn't crash.
    move([-5,-5,-5]) union(){};
    move([5,5,5]) union(){};
    sq = square(10);
    assert_equal(move("centroid", sq), move(-centroid(sq),sq));
    assert_equal(move("mean", vals), move(-mean(vals), vals));
    assert_equal(move("box", vals), move(-mean(pointlist_bounds(vals)),vals));
}
test_move();


module test_left() {
    assert_equal(left(5),[[1,0,0,-5],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(left(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(left(-5),[[1,0,0,5],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(left(5,p=[1,2,3]),[-4,2,3]);
    assert_equal(left(0,p=[1,2,3]),[1,2,3]);
    assert_equal(left(-5,p=[1,2,3]),[6,2,3]);
    // Verify that module at least doesn't crash.
    left(-5) left(0) left(5) union(){};
}
test_left();


module test_right() {
    assert_equal(right(-5),[[1,0,0,-5],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(right(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(right(5),[[1,0,0,5],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(right(-5,p=[1,2,3]),[-4,2,3]);
    assert_equal(right(0,p=[1,2,3]),[1,2,3]);
    assert_equal(right(5,p=[1,2,3]),[6,2,3]);
    // Verify that module at least doesn't crash.
    right(-5) right(0) right(5) union(){};
}
test_right();


module test_back() {
    assert_equal(back(-5),[[1,0,0,0],[0,1,0,-5],[0,0,1,0],[0,0,0,1]]);
    assert_equal(back(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(back(5),[[1,0,0,0],[0,1,0,5],[0,0,1,0],[0,0,0,1]]);
    assert_equal(back(-5,p=[1,2,3]),[1,-3,3]);
    assert_equal(back(0,p=[1,2,3]),[1,2,3]);
    assert_equal(back(5,p=[1,2,3]),[1,7,3]);
    // Verify that module at least doesn't crash.
    back(-5) back(0) back(5) union(){};
}
test_back();


module test_fwd() {
    assert_equal(fwd(5),[[1,0,0,0],[0,1,0,-5],[0,0,1,0],[0,0,0,1]]);
    assert_equal(fwd(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(fwd(-5),[[1,0,0,0],[0,1,0,5],[0,0,1,0],[0,0,0,1]]);
    assert_equal(fwd(5,p=[1,2,3]),[1,-3,3]);
    assert_equal(fwd(0,p=[1,2,3]),[1,2,3]);
    assert_equal(fwd(-5,p=[1,2,3]),[1,7,3]);
    // Verify that module at least doesn't crash.
    fwd(-5) fwd(0) fwd(5) union(){};
}
test_fwd();


module test_down() {
    assert_equal(down(5),[[1,0,0,0],[0,1,0,0],[0,0,1,-5],[0,0,0,1]]);
    assert_equal(down(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(down(-5),[[1,0,0,0],[0,1,0,0],[0,0,1,5],[0,0,0,1]]);
    assert_equal(down(5,p=[1,2,3]),[1,2,-2]);
    assert_equal(down(0,p=[1,2,3]),[1,2,3]);
    assert_equal(down(-5,p=[1,2,3]),[1,2,8]);
    // Verify that module at least doesn't crash.
    down(-5) down(0) down(5) union(){};
}
test_down();


module test_up() {
    assert_equal(up(-5),[[1,0,0,0],[0,1,0,0],[0,0,1,-5],[0,0,0,1]]);
    assert_equal(up(0),[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_equal(up(5),[[1,0,0,0],[0,1,0,0],[0,0,1,5],[0,0,0,1]]);
    assert_equal(up(-5,p=[1,2,3]),[1,2,-2]);
    assert_equal(up(0,p=[1,2,3]),[1,2,3]);
    assert_equal(up(5,p=[1,2,3]),[1,2,8]);
    // Verify that module at least doesn't crash.
    up(-5) up(0) up(5) union(){};
}
test_up();


module test_scale() {
    cb = cube(1);
    vals = [[-1,-2,-3],[1,1,1],[3,6,2],[1,2,3],[243,75,147]];
    for (val=vals) {
        assert_equal(scale(point2d(val)), [[val.x,0,0,0],[0,val.y,0,0],[0,0,1,0],[0,0,0,1]]);
        assert_equal(scale(val), [[val.x,0,0,0],[0,val.y,0,0],[0,0,val.z,0],[0,0,0,1]]);
        assert_equal(scale(val, p=[1,2,3]), v_mul([1,2,3], val));
        scale(val) union(){};
    }
    assert_equal(scale(3), [[3,0,0,0],[0,3,0,0],[0,0,3,0],[0,0,0,1]]);
    assert_equal(scale(3, p=[1,2,3]), 3*[1,2,3]);
    assert_equal(scale(3, p=cb), cube(3));
    assert_equal(scale(2, p=square(1)), square(2));
    assert_equal(scale(2, cp=[1,1], p=square(1)), square(2, center=true));
    assert_equal(scale([2,3], p=square(1)), square([2,3]));
    assert_equal(scale([2,2], cp=[0.5,0.5], p=square(1)), move([-0.5,-0.5], p=square([2,2])));
    assert_equal(scale([2,3,4], p=cb), cube([2,3,4]));
    assert_equal(scale([-2,-3,-4], p=cb), [[for (p=cb[0]) v_mul(p,[-2,-3,-4])], [for (f=cb[1]) reverse(f)]]);
    // Verify that module at least doesn't crash.
    scale(-5) scale(5) union(){};
}
test_scale();


module test_xscale() {
    vals = [1,-1,-2,-3,10,147];
    for (val=vals) {
        assert_equal(xscale(val), [[val,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
        assert_equal(xscale(val, p=[1,2,3]), [val*1,2,3]);
        xscale(val) union(){};
    }
    // Verify that module at least doesn't crash.
    xscale(-5) xscale(5) union(){};
}
test_xscale();


module test_yscale() {
    vals = [1,-1,-2,-3,10,147];
    for (val=vals) {
        assert_equal(yscale(val), [[1,0,0,0],[0,val,0,0],[0,0,1,0],[0,0,0,1]]);
        assert_equal(yscale(val, p=[1,2,3]), [1,val*2,3]);
        yscale(val) union(){};
    }
    // Verify that module at least doesn't crash.
    yscale(-5) yscale(5) union(){};
}
test_yscale();


module test_zscale() {
    vals = [1,-1,-2,-3,10,147];
    for (val=vals) {
        assert_equal(zscale(val), [[1,0,0,0],[0,1,0,0],[0,0,val,0],[0,0,0,1]]);
        assert_equal(zscale(val, p=[1,2,3]), [1,2,val*3]);
        zscale(val) union(){};
    }
    // Verify that module at least doesn't crash.
    zscale(-5) zscale(5) union(){};
}
test_zscale();


module test_mirror() {
    vals = [LEFT,RIGHT,FWD,BACK,DOWN,UP,BACK+UP+RIGHT,FWD+LEFT];
    for (val=vals) {
        v = unit(val);
        a = v.x;
        b = v.y;
        c = v.z;
        m = [
            [1-2*a*a,  -2*b*a,  -2*c*a, 0],
            [ -2*a*b, 1-2*b*b,  -2*c*b, 0],
            [ -2*a*c,  -2*b*c, 1-2*c*c, 0],
            [      0,       0,       0, 1]
        ];
        assert_approx(mirror(val), m, str("mirror(",val,")"));
        assert_approx(mirror(val, p=[1,2,3]), apply(m, [1,2,3]), str("mirror(",val,",p=...)"));
        // Verify that module at least doesn't crash.
        mirror(val) union(){};
    }
}
test_mirror();


module test_xflip() {
    assert_approx(xflip(), [[-1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_approx(xflip(p=[1,2,3]), [-1,2,3]);
    // Verify that module at least doesn't crash.
    xflip() union(){};
}
test_xflip();


module test_yflip() {
    assert_approx(yflip(), [[1,0,0,0],[0,-1,0,0],[0,0,1,0],[0,0,0,1]]);
    assert_approx(yflip(p=[1,2,3]), [1,-2,3]);
    // Verify that module at least doesn't crash.
    yflip() union(){};
}
test_yflip();


module test_zflip() {
    assert_approx(zflip(), [[1,0,0,0],[0,1,0,0],[0,0,-1,0],[0,0,0,1]]);
    assert_approx(zflip(p=[1,2,3]), [1,2,-3]);
    // Verify that module at least doesn't crash.
    zflip() union(){};
}
test_zflip();



module test_rot() {
    pts2d = 50 * [for (x=[-1,0,1],y=[-1,0,1]) [x,y]];
    pts3d = 50 * [for (x=[-1,0,1],y=[-1,0,1],z=[-1,0,1]) [x,y,z]];
    vecs2d = [
        for (x=[-1,0,1], y=[-1,0,1]) if(x!=0||y!=0) [x,y],
        polar_to_xy(1, -75),
        polar_to_xy(1,  75)
    ];
    vecs3d = [
        LEFT, RIGHT, FRONT, BACK, DOWN, UP,
        spherical_to_xyz(1, -30,  45),
        spherical_to_xyz(1,   0,  45),
        spherical_to_xyz(1,  30,  45),
        spherical_to_xyz(2, -30, 135),
        spherical_to_xyz(1,  30, 135),
        spherical_to_xyz(1, -30,  75),
        spherical_to_xyz(1,  45,  45),
    ];
    angs = [-180, -90, 0, 30, 45, 90];
    for (a = [-360*3:360:360*3]) {
        assert_approx(rot(a), affine3d_identity(), info=str("rot(",a,") != identity"));
        assert_approx(rot(a,p=pts2d), pts2d, info=str("rot(",a,",p=...), 2D"));
        assert_approx(rot(a,p=pts3d), pts3d, info=str("rot(",a,",p=...), 3D"));
    }
    assert_approx(rot(90), [[0,-1,0,0],[1,0,0,0],[0,0,1,0],[0,0,0,1]]);
    for (a=angs) {
        assert_approx(rot(a), affine3d_zrot(a), info=str("Z angle (only) = ",a));
        assert_approx(rot([a,0,0]), affine3d_xrot(a), info=str("X angle = ",a));
        assert_approx(rot([0,a,0]), affine3d_yrot(a), info=str("Y angle = ",a));
        assert_approx(rot([0,0,a]), affine3d_zrot(a), info=str("Z angle = ",a));

        assert_approx(rot(a,p=pts2d), apply(affine3d_zrot(a),pts2d), info=str("Z angle (only) = ",a, ", p=..., 2D"));
        assert_approx(rot([0,0,a],p=pts2d), apply(affine3d_zrot(a),pts2d), info=str("Z angle = ",a, ", p=..., 2D"));

        assert_approx(rot(a,p=pts3d), apply(affine3d_zrot(a),pts3d), info=str("Z angle (only) = ",a, ", p=..., 3D"));
        assert_approx(rot([a,0,0],p=pts3d), apply(affine3d_xrot(a),pts3d), info=str("X angle = ",a, ", p=..., 3D"));
        assert_approx(rot([0,a,0],p=pts3d), apply(affine3d_yrot(a),pts3d), info=str("Y angle = ",a, ", p=..., 3D"));
        assert_approx(rot([0,0,a],p=pts3d), apply(affine3d_zrot(a),pts3d), info=str("Z angle = ",a, ", p=..., 3D"));
    }
    for (xa=angs, ya=angs, za=angs) {
        assert_approx(
            rot([xa,ya,za]),
            affine3d_zrot(za) * affine3d_yrot(ya) * affine3d_xrot(xa),
            info=str("[X,Y,Z] = ",[xa,ya,za])
        );
        assert_approx(
            rot([xa,ya,za],p=pts3d),
            apply(
                affine3d_zrot(za) * affine3d_yrot(ya) * affine3d_xrot(xa),
                pts3d
            ),
            info=str("[X,Y,Z] = ",[xa,ya,za], ", p=...")
        );
    }
    for (vec1 = vecs3d) {
        for (ang = angs) {
            assert_approx(
                rot(a=ang, v=vec1),
                affine3d_rot_by_axis(vec1,ang),
                info=str("a = ",ang,", v = ", vec1)
            );
            assert_approx(
                rot(a=ang, v=vec1, p=pts3d),
                apply(affine3d_rot_by_axis(vec1,ang), pts3d),
                info=str("a = ",ang,", v = ", vec1, ", p=...")
            );
        }
    }
    for (vec1 = vecs2d) {
        for (vec2 = vecs2d) {
            assert_approx(
                rot(from=vec1, to=vec2, p=pts2d),
                apply(affine2d_zrot(v_theta(vec2)-v_theta(vec1)), pts2d),
                info=str(
                    "from = ", vec1, ", ",
                    "to = ", vec2, ", ",
                    "p=..., 2D"
                )
            );
        }
    }
    for (vec1 = vecs3d) {
        for (vec2 = vecs3d) {
            for (a = angs) {
                assert_approx(
                    rot(from=vec1, to=vec2, a=a),
                    affine3d_rot_from_to(vec1,vec2) * affine3d_rot_by_axis(vec1,a),
                    info=str(
                        "from = ", vec1, ", ",
                        "to = ", vec2, ", ",
                        "a = ", a
                    )
                );
                assert_approx(
                    rot(from=vec1, to=vec2, a=a, p=pts3d),
                    apply(
                        affine3d_rot_from_to(vec1,vec2) * affine3d_rot_by_axis(vec1,a),
                        pts3d
                    ),
                    info=str(
                        "from = ", vec1, ", ",
                        "to = ", vec2, ", ",
                        "a = ", a, ", ",
                        "p=..., 3D"
                    )
                );
            }
        }
    }
}
test_rot();


module test_xrot() {
    vals = [-270,-135,-90,45,0,30,45,90,135,147,180];
    path = path3d(pentagon(d=100), 50);
    for (a=vals) {
        m = [[1,0,0,0],[0,cos(a),-sin(a),0],[0,sin(a),cos(a),0],[0,0,0,1]];
        assert_approx(xrot(a), m);
        assert_approx(xrot(a, p=path[0]), apply(m, path[0]));
        assert_approx(xrot(a, p=path), apply(m, path));
        // Verify that module at least doesn't crash.
        xrot(a) union(){};
    }
}
test_xrot();


module test_yrot() {
    vals = [-270,-135,-90,45,0,30,45,90,135,147,180];
    path = path3d(pentagon(d=100), 50);
    for (a=vals) {
        m = [[cos(a),0,sin(a),0],[0,1,0,0],[-sin(a),0,cos(a),0],[0,0,0,1]];
        assert_approx(yrot(a), m);
        assert_approx(yrot(a, p=path[0]), apply(m, path[0]));
        assert_approx(yrot(a, p=path), apply(m, path));
        // Verify that module at least doesn't crash.
        yrot(a) union(){};
    }
}
test_yrot();


module test_zrot() {
    vals = [-270,-135,-90,45,0,30,45,90,135,147,180];
    path = path3d(pentagon(d=100), 50);
    for (a=vals) {
        m = [[cos(a),-sin(a),0,0],[sin(a),cos(a),0,0],[0,0,1,0],[0,0,0,1]];
        assert_approx(zrot(a), m);
        assert_approx(zrot(a, p=path[0]), apply(m, path[0]));
        assert_approx(zrot(a, p=path), apply(m, path));
        // Verify that module at least doesn't crash.
        zrot(a) union(){};
    }
}
test_zrot();



module test_frame_map() {
    assert(approx(frame_map(x=[1,1,0], y=[-1,1,0]), affine3d_zrot(45)));
    assert(approx(frame_map(x=[0,1,0], y=[0,0,1]), rot(v=[1,1,1],a=120)));
}
test_frame_map();


module test_skew() {
    m = affine3d_skew(sxy=2, sxz=3, syx=4, syz=5, szx=6, szy=7);
    assert_approx(skew(sxy=2, sxz=3, syx=4, syz=5, szx=6, szy=7), m);
    assert_approx(skew(sxy=2, sxz=3, syx=4, syz=5, szx=6, szy=7, p=[1,2,3]), apply(m,[1,2,3]));
    // Verify that module at least doesn't crash.
    skew(undef,2,3,4,5,6,7) union(){};
}
test_skew();


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

    check_path_apply(xrot(45), path3d(rect(100)));
    check_path_apply(yrot(45), path3d(rect(100)));
    check_path_apply(zrot(45), path3d(rect(100)));
    check_path_apply(rot([20,30,40])*scale([0.9,1.1,1])*move([10,20,30]), path3d(rect(100)));

    module check_patch_apply(mat,patch)
        assert_approx(apply(mat,patch), [for (path=patch) path3d([for (p=path) mat*concat(p,1)])]);

    flat = [for (x=[-50:25:50]) [for (y=[-50:25:50]) [x,y,0]]];
    check_patch_apply(xrot(45), flat);
    check_patch_apply(yrot(45), flat);
    check_patch_apply(zrot(45), flat);
    check_patch_apply(rot([20,30,40])*scale([0.9,1.1,1])*move([10,20,30]), flat);
}
test_apply();


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






// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
